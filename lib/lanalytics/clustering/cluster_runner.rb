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

  def self.cluster(num_centers, course_uuid, verbs)
    data = get_data_for_clustering(course_uuid, verbs)
    return [] if data.empty?

    clusterWithData(data, verbs.length, num_centers)
  end

  # This fixes the situation when only one dimension is clustered,
  # the un-scaling of the centers leads to a row, instead of a column
  def self.normalize_centers(centers, verb_length)
    return centers.to_a.flatten.map{ |center| [center] } if verb_length == 1

    centers
  end

  def self.get_data_for_clustering(course_uuid, verbs)
    course_uuid = 'c5600abf-5abf-460b-ba6f-1d030053fd79' # fake
    verbs = ALLOWED_VERBS & verbs

    return [] if verbs.length == 0

    aggregate_verbs_for_course(course_uuid, verbs).map do |row|
      [row[0]].concat(row[1, row.length].map(&:to_f))
    end
  end

  def self.set_centers(r, num_centers)
    if num_centers == 'auto'
      # Work on a sample, because it tages ages otherwise
      r.void_eval('sampled_mat <- scaled_mat[' \
                    'sample(' \
                      'nrow(scaled_mat),' \
                      'size=min(800,nrow(scaled_mat)),' \
                      'replace=FALSE' \
                    '),' \
                  ']')
      r.void_eval('pamk.best <- pamk(sampled_mat)')
      r.void_eval('num_centers <- pamk.best$nc')
    else
      r.assign('num_centers', num_centers.to_i)
    end
  end

  def self.clusterWithData(data, num_verbs, num_centers = 'auto')
    r = Rserve::Connection.new
    # Important to make sure we assign the correct data types in R
    # since error messages returned by the Rserve client gem will only be
    # 'undefined method/variable', which doesn't help much.
    r.assign('lol',      Rserve::REXP::Wrapper.wrap(data)) # lol: list of lists

    # Data frame may contain different data types, matrix just the same type
    # So lets store a data frame here, because we also have the course_uuid
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

  def self.aggregate_verbs_for_course(course_uuid, verbs)
    loader = Lanalytics::Processing::Loader::PostgresLoader.new(datasource)

    # Escaping
    course_uuid = PGconn.escape_string(course_uuid)
    verbs = verbs.map do |verb|
      PGconn.escape_string(verb)
    end

    user_uuids       = verbs.each_with_index.map{ |_verb, i| "query#{i}.user_uuid" }
    metrics          = verbs.each_with_index.map{ |_verb, i| "metric#{i}" }
    coalesce_metrics = verbs.each_with_index.map{ |verb, i| "coalesce(metric#{i}, 0) as #{verb}" }
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

    # Include all users, no matter if they have a count on a metric or not
    results = loader.execute_sql("
      select users.user_uuid, #{coalesce_metrics.join(', ')}
      from (
        select DISTINCT(user_uuid)
        from events
        where in_context->>'course_id' = '#{course_uuid}'
      ) users FULL OUTER JOIN (
         select coalesce(#{user_uuids.join(', ')}) user_uuid, #{metrics.join(', ')}
         from #{subqueries_joined}
      ) metrics on metrics.user_uuid = users.user_uuid;")

    results.values
  end

  def self.datasource
    Lanalytics::Processing::DatasourceManager.datasource('exp_api_native')
  end
end
