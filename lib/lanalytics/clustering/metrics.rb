class Lanalytics::Clustering::Metrics

  ALLOWED_VERBS = [
    'asked_question',
    'answered_question',
    'commented',
    'visited',
    'watched_question',
    'submitted_quiz',
    'video_play',
    'video_pause',
    'video_fullscreen',
    'video_seek',
    'video_change_speed',
    'video_change_size',
    'downloaded_hd_video',
    'downloaded_slides',
    'downloaded_sd_video',
    'downloaded_audio',
  ].sort

  ALLOWED_METRICS = [
    'platform_exploration',
    'textual_forum_contribution',
    'forum_observation',
    'sessions',
    'item_discovery',
    'quiz_discovery',
    'quiz_performance',
  ].sort


  def self.metrics(course_uuid, dimensions)
    verbs      = ALLOWED_VERBS & dimensions
    metrics    = ALLOWED_METRICS & dimensions
    dimensions = verbs + metrics

    return [] if verbs.length == 0 && metrics.length == 0

    verb_queries   = verbs.map{ |verb| build_verb_query(verb, course_uuid) }
    metric_queries = metrics.map{ |metric| build_metric_query(metric, course_uuid) }

    queries = verb_queries + metric_queries

    aggregate_metrics_for_course(queries, dimensions)
  end

  def self.datasource
    Lanalytics::Processing::DatasourceManager.datasource('exp_api_native')
  end

  def self.aggregate_metrics_for_course(queries, dimensions)
    user_uuids       = (0..dimensions.length - 1).map{ |i|
      "query#{i}.user_uuid"
    }.join(', ')

    coalesce_metrics = dimensions.each_with_index.map{ |dimension, i|
      "cast(coalesce(#{dimension}_metric, 0) as float) as #{dimension}"
    }.join(', ')

    metrics_not_zero = dimensions.each_with_index.map{ |dimension, i|
      "#{dimension}_metric != 0"
    }.join(' or ')

    # Every subquery aggregates one metric per user
    subqueries = queries.each_with_index.map do |query, i|
      "(#{query}) query#{i}"
    end

    # JOIN all the subqueries
    full_outer_join = dimensions.length > 1 ? "FULL OUTER JOIN" : ''
    subqueries_joined = "#{subqueries.first} #{full_outer_join} "
    subqueries.each_with_index do |query, i|
      next if i == 0
      join = " on query#{i - 1}.user_uuid = query#{i}.user_uuid"
      next_join = ' FULL OUTER JOIN '
      subqueries_joined += query + join
      subqueries_joined += next_join unless i == subqueries.length - 1
    end

    loader = Lanalytics::Processing::Loader::PostgresLoader.new(datasource)
    loader.execute_sql("
      select coalesce(#{user_uuids}) user_uuid, #{coalesce_metrics}
      from #{subqueries_joined}
      where #{metrics_not_zero}
    ").values
  end

  def self.build_verb_query(verb, course_uuid)
    "select e.user_uuid, count(*) as #{verb}_metric
     from events as e, verbs as v
     where in_context->>'course_id' = '#{course_uuid}'
     and e.verb_id = v.id
     and v.verb = '#{verb}'
     group by e.user_uuid"
  end

  def self.build_metric_query(metric, course_uuid)
    self.method(metric).call(course_uuid)
  end

  # -----------------------
  # SPECIFIC METRICS
  # -----------------------
  def self.platform_exploration(course_uuid)
    # Counts the "discovered" verbs per user

    # Some verbs don't have a course_id. This is why we only allow
    # users who have at least one other event in this course

    "select user_uuid, count(distinct(verb_id)) as platform_exploration_metric
     from events
     where user_uuid in (
       select distinct(user_uuid)
       from events
       where in_context->>'course_id' = '#{course_uuid}'
     )
     group by user_uuid"
  end

  def self.textual_forum_contribution(course_uuid)
    # Counts the sum of answered_question, commented, asked_question

    "select e.user_uuid, count(*) as textual_forum_contribution_metric
     from events as e, verbs as v
     where in_context->>'course_id' = '#{course_uuid}'
     and e.verb_id = v.id
     and (v.verb = 'asked_question' or v.verb = 'answered_question' or v.verb = 'commented')
     group by e.user_uuid"
  end

  def self.forum_observation(course_uuid)
    # TODO: Get course_code and add visited_page where page id = /courses/<course_code>/pinboard

    self.build_verb_query('watched_question', course_uuid)
  end

  def self.sessions(course_uuid)
    # Counts number of sessions where one sessions = events within <= 30 minutes gap

    "select q.user_uuid, count(*) as sessions_metric
     from (
       select
         user_uuid,
         created_at,
         lead(created_at, 1) over (partition by user_uuid order by created_at desc) as created_at_next
       from events
       where user_uuid in (
         select distinct(user_uuid)
         from events
         where in_context->>'course_id' = '#{course_uuid}'
       )
     ) as q
     where extract(epoch from (q.created_at - q.created_at_next)) > 1800
     group by q.user_uuid"
  end

  def self.quiz_discovery(course_uuid)
    "select e.user_uuid, count(distinct(r.uuid)) as quiz_discovery_metric
     from events as e, verbs as v, resources as r
     where e.verb_id = v.id
     and e.resource_id = r.id
     and e.in_context->>'course_id' = '#{course_uuid}'
     and r.resource_type = 'quiz'
     and v.verb = 'visited'
     group by e.user_uuid"
  end

  def self.item_discovery(course_uuid)
    "select e.user_uuid, count(distinct(r.uuid)) as item_discovery_metric
     from events as e, verbs as v, resources as r
     where e.verb_id = v.id
     and e.resource_id = r.id
     and e.in_context->>'course_id' = '#{course_uuid}'
     and v.verb = 'visited'
     group by e.user_uuid"
  end

  def self.quiz_performance(course_uuid)
    "select e.user_uuid, avg(cast(e.in_context->>'points' as float)) as quiz_performance_metric
     from events as e, verbs as v, resources as r
     where e.verb_id = v.id
     and e.resource_id = r.id
     and e.in_context->>'course_id' = '#{course_uuid}'
     and v.verb = 'submitted_quiz'
     and e.in_context->>'quiz_type' = 'selftest'
     group by e.user_uuid"
  end
end
