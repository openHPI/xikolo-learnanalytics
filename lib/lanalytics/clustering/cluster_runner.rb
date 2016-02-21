require 'rserve'
require 'matrix'

class Lanalytics::Clustering::ClusterRunner

  ALLOWED_VERBS = [
    'asked_question',
    'answered_question',
    'commented',
    'visited',
    'watched_question'
  ].sort


  STRATEGY = :kmeans

  # Currently takes too long: avg O(n log n), worst case O(n^2)
  # So this currently produces a timeout (locally), but worth trying
  # again because it will likely produce better results
  # STRATEGY = :dbscan


  def self.cluster(num_centers, course_uuid, verbs)
    metrics = get_metrics_for_clustering(course_uuid, verbs)

    return [] if metrics.empty?

    cluster_with_metrics(metrics, verbs.length, num_centers)
  end

  # This fixes the situation when only one dimension is clustered,
  # the un-scaling of the centers leads to a row, instead of a column
  def self.normalize_centers(centers, verb_length)
    return centers.to_a.flatten.map{ |center| [center] } if verb_length == 1

    centers
  end

  def self.get_metrics_for_clustering(course_uuid, verbs)
    verbs = ALLOWED_VERBS & verbs

    return [] if verbs.length == 0

    aggregate_metrics_for_course(course_uuid, verbs)
  end

  def self.set_centers(r, num_centers)
    if num_centers == 'auto'
      # Options as recommended for large data sets
      # See https://cran.r-project.org/web/packages/fpc/fpc.pdf
      r.void_eval('pamk.best <- pamk(scaled_mat, usepam=FALSE, criterion="asw")')
      r.void_eval('num_centers <- pamk.best$nc')
    else
      r.assign('num_centers', num_centers.to_i)
    end
  end

  def self.cluster_kmeans(r, num_verbs, num_centers)
    # Possibly find centers automatically
    set_centers(r, num_centers)

    # Cluster and append results to the data frame
    r.void_eval('clustering <- kmeans(scaled_mat, center=num_centers)')
    r.void_eval("frame[,#{num_verbs + 2}] <- clustering$cluster")

    # To read the cluster centers as a human, un-apply the normalization
    # Note: When cluster centers are one-dimensional (one verb as input)
    #       row and col will be switched, which means we need to normalize
    r.void_eval('centers <- t(apply(' \
                  'clustering$centers, ' \
                  '1, ' \
                  'function(r) ' \
                    "r * attr(scaled_mat, 'scaled:scale') + " \
                    "attr(scaled_mat, 'scaled:center')" \
                '))')

    {
      clustered_data: r.eval('frame').to_ruby,
      clusters: {
        sizes:     r.eval('clustering$size').to_ruby,
        centers:   normalize_centers(r.eval('centers').to_ruby, num_verbs),
        totss:     r.eval('clustering$totss').to_ruby,
        betweenss: r.eval('clustering$betweenss').to_ruby,
        withinss:  r.eval('clustering$withinss').to_ruby
      }
    }
  end

  def self.cluster_dbscan(r, num_verbs)
    #
    # TODO: This produces a TimeoutError, but will likely return better clustering results.
    #
    r.void_eval('clustering <- dbscan(scaled_mat, 0.1)')
    r.void_eval("frame[,#{num_verbs + 2}] <- clustering$cluster")

    r.void_eval('sizes <- as.matrix(table(clustering$cluster))')

    {
      clustered_data: r.eval('frame').to_ruby,
      clusters: {
        sizes:   r.eval('sizes').to_ruby.to_a.flatten,
      }
    }
  end

  def self.cluster_with_metrics(metrics, num_verbs, num_centers = 'auto')
    r = Rserve::Connection.new(Lanalytics::RSERVE_CONFIG)
    # Important to make sure we assign the correct data types in R
    # since error messages returned by the Rserve client gem will only be
    # 'undefined method/variable', which doesn't help much.
    r.assign('lol',      Rserve::REXP::Wrapper.wrap(metrics)) # lol: list of lists

    # Data frame may contain different data types, matrix just the same type
    # So lets store a data frame here, because we also have the user_uuids
    r.void_eval('frame <- do.call(rbind.data.frame, lol)')
    (2..num_verbs + 1).each do |num| # R indices start with 1
      r.void_eval("frame[,#{num}] <- as.numeric(frame[,#{num}])")
    end

    cluster_data_dimensions = (2..num_verbs + 1).to_a.join(',')

    # Convert everything but the user_uuid to a matrix for clustering
    r.void_eval("mat <- data.matrix(frame[,c(#{cluster_data_dimensions})])")

    # Normalize the values, since e.g.
    # the difference of 1 or 2 questions answered
    # is more significant than the difference of 1 or 2 page views.
    r.void_eval('scaled_mat <- scale(mat)')

    if STRATEGY == :kmeans
      cluster_kmeans(r, num_verbs, num_centers)
    elsif STRATEGY == :dbscan
      cluster_dbscan(r, num_verbs)
    end
  end

  def self.aggregate_metrics_for_course(course_uuid, verbs)
    loader = Lanalytics::Processing::Loader::PostgresLoader.new(datasource)

    # Escaping
    course_uuid = PGconn.escape_string(course_uuid)
    verbs = verbs.map do |verb|
      PGconn.escape_string(verb)
    end

    user_uuids       = verbs.each_with_index.map{ |_verb, i| "query#{i}.user_uuid" }.join(', ')
    coalesce_metrics = verbs.each_with_index.map{ |verb, i| "coalesce(metric#{i}, 0) as #{verb}" }.join(', ')
    metrics_not_zero = verbs.each_with_index.map{ |verb, i| "metric#{i} != 0" }.join(' or ')
    # Every subquery aggregates one metric per user
    subqueries       = verbs.each_with_index.map do |verb, i|
      "(select e.user_uuid, count(*) as metric#{i}
        from events as e, verbs as v
        where in_context->>'course_id' = '#{course_uuid}'
        and e.verb_id = v.id
        and v.verb = '#{verb}'
        group by e.user_uuid
      ) query#{i}"
    end
    full_outer_join = verbs.length > 1 ? "FULL OUTER JOIN" : ''
    subqueries_joined = "#{subqueries.first} #{full_outer_join} "
    subqueries.each_with_index do |query, i|
      next if i == 0
      join = " on query#{i - 1}.user_uuid = query#{i}.user_uuid"
      next_join = ' FULL OUTER JOIN '
      subqueries_joined += query + join
      subqueries_joined += next_join unless i == subqueries.length - 1
    end

    loader.execute_sql("
      select coalesce(#{user_uuids}) user_uuid, #{coalesce_metrics}
      from #{subqueries_joined}
      where #{metrics_not_zero}
    ").values.map do |row|
      [row[0]].concat(row[1, row.length].map(&:to_f))
    end
  end

  def self.datasource
    Lanalytics::Processing::DatasourceManager.datasource('exp_api_native')
  end
end
