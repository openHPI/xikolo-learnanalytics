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

  # This fixes the situation when only one dimension is clustered,
  # the un-scaling of the centers leads to a row, instead of a column
  def self.normalize_centers(centers, verb_length)
    return centers.to_a.flatten.map{ |center| [center] } if verb_length == 1

    centers
  end

  def self.cluster(num_centers, course_uuid, verbs)
    r = Rserve::Connection.new

    # fake course_uuid
    course_uuid = 'c5600abf-5abf-460b-ba6f-1d030053fd79'
    verbs = ALLOWED_VERBS & verbs
    return [] if verbs.length == 0

    data = aggregate_verbs_for_course(course_uuid, verbs).map do |row|
      [row[0]].concat(row[1, row.length].map(&:to_f))
    end
    return [] if data.empty?

    # Important to make sure we assign the correct data types in R
    # since error messages returned by the Rserve client gem will only be
    # 'undefined method/variable', which doesn't help much.
    r.assign('lol',      Rserve::REXP::Wrapper.wrap(data)) # lol: list of lists
    r.assign('ncenters', num_centers.to_i)

    # Data frame may contain different data types, matrix just the same type
    # So lets store a data frame here.
    r.void_eval('frame <- do.call(rbind.data.frame, lol)')
    (2..verbs.length + 1).each do |num| # R indices start with 1
      r.void_eval("frame[,#{num}] <- as.numeric(frame[,#{num}])")
    end
    cluster_data_dimensions = (2..verbs.length + 1).to_a.join(',')

    # Convert everything but the user_uuid to a matrix for clustering
    r.void_eval("mat <- data.matrix(frame[,c(#{cluster_data_dimensions})])")

    # Normalize the values, since e.g.
    # the difference of 1 or 2 questions answered
    # is more significant than the difference of 1 or 2 page views.
    r.void_eval('scaled_mat <- scale(mat)')

    # Cluster and append results to the data frame
    r.void_eval('clustering <- kmeans(scaled_mat, center=ncenters)')
    r.void_eval("frame[,#{verbs.length + 2}] <- clustering$cluster")

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
        centers:   normalize_centers(r.eval('centers').to_ruby, verbs.length),
        totss:     r.eval('clustering$totss').to_ruby,
        betweenss: r.eval('clustering$betweenss').to_ruby,
        withinss:  r.eval('clustering$withinss').to_ruby,
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

    user_uuids       = verbs.each_with_index.map{ |_verb, i| "q#{i}.user_uuid" }
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
      ) q#{i}"
    end
    full_outer_join = verbs.length > 1 ? "FULL OUTER JOIN" : ''
    subqueries_joined = "#{subqueries.first} #{full_outer_join} "
    subqueries.each_with_index do |query, i|
      next if i == 0
      join = " on q#{i - 1}.user_uuid = q#{i}.user_uuid"
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
