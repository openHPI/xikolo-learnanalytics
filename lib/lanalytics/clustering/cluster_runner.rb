require 'rserve'
require 'matrix'

class Lanalytics::Clustering::ClusterRunner

  def self.cluster(num_centers, verb1, verb2, course_uuid)
    r = Rserve::Connection.new

    data = aggregate_two_verbs_for_course(verb1, verb2, course_uuid).values.map do |row|
      # convert last two columns to float
      [row[0], row[1].to_f, row[2].to_f]
    end

    # Important to make sure we set the correct data types in R
    # since error messages returned by the Rserve client gem will only be
    # 'undefined method/variable', which doesn't help much.
    r.assign('lol',      Rserve::REXP::Wrapper.wrap(data)) # (lol: list of lists)
    r.assign('ncenters', num_centers.to_i)

    # Data frame may contain different data types, matrix just the same type
    # So lets store a data frame here.
    r.void_eval('frame <- do.call(rbind.data.frame, lol)')
    r.void_eval('frame[,2] <- as.numeric(frame[,2])')
    r.void_eval('frame[,3] <- as.numeric(frame[,3])')
    # Convert everything but the user_uuid to a matrix for clustering
    r.void_eval('mat = data.matrix(frame[,c(2,3)])')
    # Cluster and assign results
    r.void_eval('clustering <- kmeans(scale(mat), center=ncenters)')
    r.void_eval('frame[,4] <- clustering$cluster')

    r.eval('frame').to_ruby
  end

  def self.aggregate_two_verbs_for_course(verb1, verb2, course_uuid)
    loader = Lanalytics::Processing::Loader::PostgresLoader.new(datasource)

    # Escaping
    verb1       = PGconn.escape_string(verb1)
    verb2       = PGconn.escape_string(verb2)
    course_uuid = PGconn.escape_string(course_uuid)

    # Join all users with the sum of the two verbs
    # Include users that have a 0 count on one or both of them (full outer join)
    loader.execute_sql("
      select users.user_uuid,
             coalesce(metric1, 0) as #{verb1},
             coalesce(metric2, 0) as #{verb2}
      from (
        select DISTINCT(user_uuid)
        from events
        where in_context->>'course_id' = '#{course_uuid}'
      ) users FULL OUTER JOIN (
        select coalesce(q1.user_uuid, q2.user_uuid) user_uuid, metric1, metric2
        from (
          select e.user_uuid, count(*) as metric1
          from events as e, verbs as v
          where in_context->>'course_id' = '#{course_uuid}'
          and e.verb_id = v.id
          and v.verb = '#{verb1}'
          group by e.user_uuid
        ) q1 FULL OUTER JOIN (
          select e.user_uuid, count(*) as metric2
          from events as e, verbs as v
          where in_context->>'course_id' = '#{course_uuid}'
          and e.verb_id = v.id
          and v.verb = '#{verb2}'
          group by e.user_uuid
        ) q2 on q1.user_uuid = q2.user_uuid
      ) metrics on metrics.user_uuid = users.user_uuid;")
  end

  def self.datasource
    Lanalytics::Processing::DatasourceManager.datasource('exp_api_native')
  end
end
