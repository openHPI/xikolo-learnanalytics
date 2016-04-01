class Lanalytics::Clustering::Runner
  # [performance] local 2GHz, 8GB RAM: ~5 sec. for 15000 students along 3 metrics
  STRATEGY = :kmeans

  # Currently takes too long: avg O(n log n), worst case O(n^2)
  # [performance] local 2GHz, 8GB RAM: ~100 sec. for 15000 students along 3 metrics
  #
  # STRATEGY = :dbscan


  # Quicker than dbscan, but slower than kmeans.
  # [performance] local 2GHz, 8GB RAM: ~16 sec. for 15000 students along 3 metrics
  # BUT takes a LOT - O(n^2) space to compute a distance matrix.
  # => not sure if feasible on a production system.
  #
  # STRATEGY = :hclust


  def self.connection
    conn = Rserve::Connection.class_eval('@@connected_object')

    if conn.nil?
      conn = Rserve::Connection.new(Lanalytics::RSERVE_CONFIG)
    end

    conn
  end

  def self.cluster(num_centers, course_uuid, dimensions)
    dimensions_data = Lanalytics::Clustering::Dimensions
      .query(course_uuid, dimensions)
      .values

    return [] if dimensions_data.empty?

    start_time = Time.now
    results = cluster_with_dimensions_data(dimensions_data, dimensions.length, num_centers)
    end_time = Time.now

    Sidekiq.logger.info { "[Performance] - Clustering took: #{end_time - start_time} seconds" }
    Rails.logger.info { "[Performance] - Clustering took: #{end_time - start_time} seconds" }

    results
  end

  def self.cluster_with_dimensions_data(dimensions_data, num_dimensions, num_centers = 'auto')
    r = connection
    # Important to make sure we assign the correct data types in R
    # since error messages returned by the Rserve client gem will only be
    # 'undefined method/variable', which doesn't help much.
    r.assign('lol', Rserve::REXP::Wrapper.wrap(dimensions_data)) # lol: list of lists

    # Data frame may contain different data types, matrix just the same type
    # So lets store a data frame here, because we also have the user_uuids
    r.void_eval('frame <- do.call(rbind.data.frame, lol)')
    (2..num_dimensions + 1).each do |num| # R indices start with 1
      r.void_eval("frame[,#{num}] <- as.numeric(as.character(frame[,#{num}]))")
    end

    cluster_data_dimensions = (2..num_dimensions + 1).to_a.join(',')

    # Convert everything but the user_uuid to a matrix for clustering
    r.void_eval("mat <- data.matrix(frame[,c(#{cluster_data_dimensions})])")

    # Normalize the values, since e.g.
    # the difference of 1 or 2 questions answered
    # is more significant than the difference of 1 or 2 page views.
    r.void_eval('scaled_matrix <- scale(mat)')

    if STRATEGY == :kmeans
      results = cluster_kmeans(r, num_dimensions, num_centers)
    elsif STRATEGY == :dbscan
      results = cluster_dbscan(r, num_dimensions)
    elsif STRATEGY == :hclust
      results = cluster_hclust(r, num_dimensions, num_centers)
    end

    # Add corellation matrix for info
    results.merge(correlations: r.eval('cor(mat)').to_ruby.to_a)
  end

  def self.centers(r)
    r.void_eval('centers <- as.matrix(aggregate(frame,list(frame[,ncol(frame)]), FUN=mean))')

    r.eval('centers').to_ruby.to_a.map do |row|
      # First and last are grouped cluster assignments, row[1] is user_uuid
      row[2..row.length-2]
    end
  end


  # -----------------------
  # SPECIFIC STRATEGY: KMEANS
  # -----------------------

  # This fixes the situation when only one dimension is clustered,
  # the un-scaling of the centers leads to a row, instead of a column
  def self.normalize_centers(centers, num_dimensions)
    return centers.to_a.flatten.map{ |center| [center] } if num_dimensions == 1

    centers
  end

  def self.set_centers(r, num_centers)
    if num_centers == 'auto'
      # Options as recommended for large data sets
      # See https://cran.r-project.org/web/packages/fpc/fpc.pdf
      r.void_eval('pamk.best <- pamk(scaled_matrix, usepam=FALSE, criterion="asw")')
      r.void_eval('num_centers <- pamk.best$nc')
    else
      r.assign('num_centers', num_centers.to_i)
    end
  end

  def self.cluster_kmeans(r, num_dimensions, num_centers)
    # Possibly find centers automatically
    set_centers(r, num_centers)

    # Cluster and append results to the data frame
    r.void_eval('clustering <- kmeans(scaled_matrix, center=num_centers)')
    r.void_eval("frame[,#{num_dimensions + 2}] <- clustering$cluster")

    # To read the cluster centers as a human, un-apply the normalization
    # Note: When cluster centers are one-dimensional (one dimension as input)
    #       row and col will be switched, which means we need to normalize
    r.void_eval('centers <- t(apply(' \
                  'clustering$centers, ' \
                  '1, ' \
                  'function(r) ' \
                    "r * attr(scaled_matrix, 'scaled:scale') + " \
                    "attr(scaled_matrix, 'scaled:center')" \
                '))')

    centers = r.eval('centers').to_ruby

    {
      clustered_data: r.eval('frame').to_ruby,
      clusters: {
        sizes:     r.eval('clustering$size').to_ruby,
        centers:   normalize_centers(centers, num_dimensions),
        totss:     r.eval('clustering$totss').to_ruby,
        betweenss: r.eval('clustering$betweenss').to_ruby,
        withinss:  r.eval('clustering$withinss').to_ruby
      }
    }
  end

  # -----------------------
  # SPECIFIC STRATEGY: DBSCAN
  # -----------------------
  def self.cluster_dbscan(r, num_dimensions)
    # density-reachability of 0.1 is arbitrarily chosen for testing
    # -> likely not ideal yet
    r.void_eval('clustering <- dbscan(scaled_matrix, 0.1)')
    r.void_eval("frame[,#{num_dimensions + 2}] <- clustering$cluster")

    r.void_eval('sizes <- as.matrix(table(clustering$cluster))')
    r.void_eval('centers <- as.matrix(aggregate(frame,list(frame[,ncol(frame)]), FUN=mean))')

    {
      clustered_data: r.eval('frame').to_ruby,
      clusters: {
        sizes:   r.eval('sizes').to_ruby.to_a.flatten,
        centers: centers(r)
      }
    }
  end

  # -----------------------
  # SPECIFIC STRATEGY: HCLUST
  # -----------------------
  def self.cluster_hclust(r, num_dimensions, num_centers)
    # Possibly find centers automatically
    set_centers(r, num_centers)

    r.void_eval('dist <- dist(scaled_matrix)')
    r.void_eval('clustering <- hclust(dist)')
    r.void_eval('clusters <- cutree(clustering, k=num_centers)')
    r.void_eval("frame[,#{num_dimensions + 2}] <- clusters")

    r.void_eval('sizes <- as.matrix(table(clusters))')

    {
      clustered_data: r.eval('frame').to_ruby,
      clusters: {
        sizes:   r.eval('sizes').to_ruby.to_a.flatten,
        centers: centers(r)
      }
    }
  end
end
