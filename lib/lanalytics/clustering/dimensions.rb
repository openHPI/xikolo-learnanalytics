# frozen_string_literal: true

# legacy code; still used by metrics

class Lanalytics::Clustering::Dimensions # rubocop:disable Metrics/ClassLength
  # To add a verb:
  #   1) make sure it has the course id in 'in_context'
  #   2) add it to the list
  ALLOWED_VERBS = %w[
    asked_question
    answered_question
    commented
    visited
    watched_question
    submitted_quiz
    video_play
    video_pause
    video_fullscreen
    video_seek
    video_change_speed
    video_change_size
    downloaded_hd_video
    downloaded_slides
    downloaded_sd_video
    downloaded_audio
    toggled_subscription
  ].sort

  # To add a metric
  #   1) add it to the list (e.g. named 'foo')
  #   2) define a function below named like the metric
  #   3) make sure the function returns
  #      - the user uuid
  #      - the aggregated metric, named: foo_metric
  #   Indentation indicates metric hierarchy (some metrics are abstractions / aggregations of others)
  #
  ALLOWED_METRICS = %w[
    sessions
    total_session_duration
    average_session_duration
    platform_exploration
    survey_submissions
    download_activity
    unique_video_downloads_activity
    unique_slide_downloads_activity
    video_player_activity
    unique_video_play_activity
    forum_activity
    textual_forum_contribution
    forum_observation
    item_discovery
    video_discovery
    quiz_discovery
    quiz_performance
    ungraded_quiz_performance
    graded_quiz_performance
    main_quiz_performance
    bonus_quiz_performance
    course_performance
  ].sort
  # rubocop:enable all

  MIN_SESSION_GAP_SECONDS = 1800

  def self.query(course_uuid, dimensions, user_uuids = nil)
    verbs      = ALLOWED_VERBS & dimensions
    metrics    = ALLOWED_METRICS & dimensions
    dimensions = (verbs + metrics).sort

    return [] if verbs.empty? && metrics.empty?

    verb_queries   = verbs.map {|verb| build_verb_query(verb, course_uuid, user_uuids) }
    metric_queries = metrics.map {|metric| build_metric_query(metric, course_uuid, user_uuids) }

    queries = verb_queries + metric_queries

    aggregate_dimensions_data(queries, dimensions, user_uuids)
  end

  def self.datasource
    Lanalytics::Processing::DatasourceManager.datasource('exp_events_postgres')
  end

  def self.perform_query(query)
    loader = Lanalytics::Processing::Loader::PostgresLoader.new(datasource)

    start_time = Time.zone.now
    result = loader.execute_sql(query)
    duration = Time.zone.now - start_time

    Sidekiq.logger.debug { "[Performance] - Data extraction took: #{duration}" }
    Rails.logger.debug { "[Performance] - Data extraction took: #{duration}" }

    result
  end

  # -----------------------
  # COMBINE DIMENSIONS - BUILD A SINGLE BIG QUERY
  # -----------------------
  def self.aggregate_dimensions_data(queries, dimensions, cluster_group_user_uuids)
    user_uuids = (0..dimensions.length - 1).map do |i|
      "query#{i}.user_uuid"
    end.join(', ')

    coalesce_dimensions = dimensions.each_with_index.map do |dimension, _i|
      "cast(coalesce(#{dimension}_metric, 0) as float) as #{dimension}"
    end.join(', ')

    dimensions_not_zero = dimensions.map do |dimension|
      "#{dimension}_metric != 0"
    end.join(' or ')

    max_dimensions = dimensions.map do |dimension|
      "max(#{dimension}) as #{dimension}"
    end.join(', ')

    # Every subquery aggregates one metric per user
    subqueries = queries.each_with_index.map do |query, i|
      "(#{query}) query#{i}"
    end

    # JOIN all the subqueries
    full_outer_join = dimensions.length > 1 ? 'FULL OUTER JOIN' : ''
    subqueries_joined = "#{subqueries.first} #{full_outer_join} "
    subqueries.each_with_index do |query, i|
      next if i == 0

      join = " on query#{i - 1}.user_uuid = query#{i}.user_uuid"
      next_join = ' FULL OUTER JOIN '
      subqueries_joined += query + join
      subqueries_joined += next_join unless i == subqueries.length - 1
    end

    final_query = "
      select user_uuid, #{max_dimensions}
      from (
        select coalesce(#{user_uuids}) user_uuid, #{coalesce_dimensions}
        from #{subqueries_joined}
        where #{dimensions_not_zero}
      ) fin
      group by user_uuid
    "

    if cluster_group_user_uuids.present?
      dimension_selection = dimensions.map do |dimension|
        "avg(subq.#{dimension}) as #{dimension}"
      end.join(', ')
      cluster_group_filter = cluster_group_user_uuids.map {|uuid| "'#{uuid}'" }.join(', ')

      final_query = "
        select #{dimension_selection}
        from (#{final_query}) subq
        where subq.user_uuid in (#{cluster_group_filter})
      "
    end

    perform_query(final_query)
  end

  def self.build_verb_query(verb, course_uuid = nil, user_uuids = nil)
    s1 = "select e.user_uuid, count(*) as #{verb}_metric
     from events as e, verbs as v
     where e.verb_id = v.id "
    s2 = course_uuid.present? ? " and in_context->>'course_id' = '#{course_uuid}'" : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = " and v.verb = '#{verb}'
     group by e.user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.build_metric_query(metric, course_uuid, user_uuids = nil)
    method(metric).call(course_uuid, user_uuids)
  end

  def self.userfilter_query(user_uuids, append_and: false)
    result = if user_uuids.size == 1
               " user_uuid = '#{user_uuids.first}'"
             else
               " user_uuid ANY (#{user_uuids.explode(',')})"
             end
    append_and ? " AND #{result}" : " WHERE #{result}"
  end

  # -----------------------
  # SPECIFIC METRICS
  # -----------------------

  def self.platform_exploration(course_uuid, user_uuids = nil)
    # Counts the "discovered" verbs per user

    # Some verbs don't have a course_id. This is why we only allow
    # users who have at least one other event in this course
    s1 = "select user_uuid, count(distinct(verb_id)) as platform_exploration_metric
     from events
     where user_uuid in (
       select user_uuid
       from events "
    s2 = course_uuid.present? ? " where in_context->>'course_id' = '#{course_uuid}'" : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: course_uuid.present?) : ''
    s4 = " group by user_uuid
     )
     group by user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.textual_forum_contribution(course_uuid, user_uuids = nil)
    # Counts the sum of answered_question, commented, asked_question
    s1 = "select e.user_uuid, count(*) as textual_forum_contribution_metric
     from events as e, verbs as v
     where e.verb_id = v.id "
    s2 = course_uuid.present? ? " and in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = " and (v.verb = 'asked_question' or v.verb = 'answered_question' or v.verb = 'commented')
     group by e.user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.forum_observation(course_uuid, user_uuids = nil)
    # TODO: Get course_code and add visited_page where page id = /courses/<course_code>/pinboard
    s1 = "select e.user_uuid, count(*) as forum_observation_metric
     from events as e, verbs as v
     where e.verb_id = v.id "
    s2 = course_uuid.present? ? " and in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = " and (v.verb = 'visited_question' or v.verb = 'toggled_subscription'
     or v.verb = 'visited_pinboard')
     group by e.user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.quiz_discovery(course_uuid, user_uuids = nil)
    # Counts number of distinct quizzes visited
    s1 = "select e.user_uuid, count(distinct(r.uuid)) as quiz_discovery_metric
     from events as e, verbs as v, resources as r
     where e.verb_id = v.id
     and e.resource_id = r.id "
    s2 = course_uuid.present? ? " and e.in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = " and r.resource_type = 'quiz'
     and v.verb = 'visited_item'
     group by e.user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.item_discovery(course_uuid, user_uuids = nil)
    # Counts number of distinct items visited

    s1 = "select e.user_uuid, count(distinct(r.uuid)) as item_discovery_metric
     from events as e, verbs as v, resources as r
     where e.verb_id = v.id
     and e.resource_id = r.id "
    s2 = course_uuid.present? ? " and e.in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = " and v.verb = 'visited_item'
     group by e.user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.video_discovery(course_uuid, user_uuids = nil)
    # Counts number of distinct videos visited

    s1 = "select e.user_uuid, count(distinct(r.uuid)) as video_discovery_metric
     from events as e, verbs as v, resources as r
     where e.verb_id = v.id
     and e.resource_id = r.id "
    s2 = course_uuid.present? ? " and e.in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = " and r.resource_type = 'video'
     and v.verb = 'visited_item'
     group by e.user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.quiz_performance(course_uuid, user_uuids = nil)
    quiz_type_performance(course_uuid, 'quiz', %w[main bonus selftest], user_uuids)
  end

  def self.graded_quiz_performance(course_uuid, user_uuids = nil)
    quiz_type_performance(course_uuid, 'graded_quiz', %w[main bonus], user_uuids)
  end

  def self.ungraded_quiz_performance(course_uuid, user_uuids = nil)
    quiz_type_performance(course_uuid, 'ungraded_quiz', ['selftest'], user_uuids)
  end

  def self.main_quiz_performance(course_uuid, user_uuids = nil)
    quiz_type_performance(course_uuid, 'main_quiz', ['main'], user_uuids)
  end

  def self.bonus_quiz_performance(course_uuid, user_uuids = nil)
    quiz_type_performance(course_uuid, 'bonus_quiz', ['bonus'], user_uuids)
  end

  def self.quiz_type_performance(course_uuid, metric, types, user_uuids = nil)
    type_query = types.map {|type| "e.in_context->>'quiz_type' = '#{type}'" }
      .join(' or ')

    s1 = "select e.user_uuid, round(
        avg(
          case when (e.in_context->>'max_points')::float = 0 then 0
            else (e.in_context->>'points')::float /
                 (e.in_context->>'max_points')::float
          end
        )::numeric
      ,3) as #{metric}_performance_metric
     from events as e, verbs as v
     where e.verb_id = v.id "
    s2 = course_uuid.present? ? " and e.in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = " and v.verb = 'submitted_quiz'
     and (#{type_query})
     and (e.in_context->>'max_points') is not null
     group by e.user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.sessions(course_uuid, user_uuids = nil)
    # working_time is null for the first lag
    # -> users with any event in this course will have at least 1 session
    # sessions will never be 0

    s1 = "select
      user_uuid,
      count(CASE WHEN working_time is null or extract(epoch from working_time) > #{MIN_SESSION_GAP_SECONDS}
            THEN 1
            ELSE null END) as sessions_metric
     from (
       select
         user_uuid,
         created_at - lag(created_at) over (partition by user_uuid
                                            order by created_at) as working_time
       from events "
    s2 = course_uuid.present? ? " where in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: course_uuid.present?) : ''
    s4 = " ) as q
     group by user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.total_session_duration(course_uuid, user_uuids = nil)
    s1 = "select user_uuid, extract(epoch from sum(working_time)) as total_session_duration_metric
    from(
      select
        user_uuid,
        created_at - lag(created_at) over (partition by user_uuid
                                           order by created_at) as working_time
      from events "
    s2 = course_uuid.present? ? " where in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: course_uuid.present?) : ''
    s4 = " ) q
    where extract(epoch from (working_time)) <= #{MIN_SESSION_GAP_SECONDS}
    group by user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.average_session_duration(course_uuid, user_uuids = nil)
    # working_time is null for the first lag
    # -> users with any event in this course will have at least 1 session

    s1 = "select user_uuid,
      round(
        sum(CASE WHEN working_time < #{MIN_SESSION_GAP_SECONDS}
            THEN working_time
            ELSE 0 END) /
        count(CASE WHEN working_time is null or working_time >= #{MIN_SESSION_GAP_SECONDS}
               THEN 1
               ELSE null END)
      ) as average_session_duration_metric
    from (
      select
        user_uuid,
        extract(epoch from
          created_at - lag(created_at) over (partition by user_uuid
                                             order by created_at)
        ) as working_time
      from events "
    s2 = course_uuid.present? ? " where in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: course_uuid.present?) : ''
    s4 = " ) as q
    group by user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.download_activity(course_uuid, user_uuids = nil)
    s1 = "select e.user_uuid, count(*) as download_activity_metric
     from events as e, verbs as v
     where e.verb_id = v.id
     and (v.verb = 'downloaded_slides' or
          v.verb = 'downloaded_sd_video' or
          v.verb = 'downloaded_hd_video' or
          v.verb = 'downloaded_audio') "
    s2 = course_uuid.present? ? " and in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = ' group by e.user_uuid'
    s1 + s2 + s3 + s4
  end

  def self.unique_video_downloads_activity(course_uuid, user_uuids = nil)
    s1 = "select e.user_uuid, count(distinct(r.uuid)) as unique_video_downloads_activity_metric
     from events as e, verbs as v, resources as r
     where e.verb_id = v.id
     and (v.verb = 'downloaded_sd_video' or
          v.verb = 'downloaded_hd_video' or
          v.verb = 'downloaded_hls_video')
     and e.resource_id = r.id "
    s2 = course_uuid.present? ? " and in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = ' group by e.user_uuid'
    s1 + s2 + s3 + s4
  end

  def self.unique_slide_downloads_activity(course_uuid, user_uuids = nil)
    s1 = "select e.user_uuid, count(distinct(r.uuid)) as unique_slide_downloads_activity_metric
     from events as e, verbs as v, resources as r
     where e.verb_id = v.id
     and v.verb = 'downloaded_slides'
     and e.resource_id = r.id "
    s2 = course_uuid.present? ? " and in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = ' group by e.user_uuid'
    s1 + s2 + s3 + s4
  end

  def self.video_player_activity(course_uuid, user_uuids = nil)
    s1 = "select e.user_uuid, count(*) as video_player_activity_metric
     from events as e, verbs as v
     where e.verb_id = v.id "
    s2 = course_uuid.present? ? " and in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = " and (v.verb = 'video_play' or
          v.verb = 'video_pause' or
          v.verb = 'video_fullscreen' or
          v.verb = 'video_change_speed' or
          v.verb = 'video_change_size' or
          v.verb = 'video_seek')
     group by e.user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.unique_video_play_activity(course_uuid, user_uuids = nil)
    # Counts number of unique videos played

    s1 = "select e.user_uuid, count(distinct(r.uuid)) as unique_video_play_activity_metric
     from events as e, verbs as v, resources as r
     where e.verb_id = v.id
     and e.resource_id = r.id "
    s2 = course_uuid.present? ? " and e.in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = " and v.verb = 'video_play'
     group by e.user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.forum_activity(course_uuid, user_uuids = nil)
    s1 = "select e.user_uuid, count(*) as forum_activity_metric
      from events as e, verbs as v
      where e.verb_id = v.id "
    s2 = course_uuid.present? ? " and in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = " and (v.verb = 'asked_question' or
          v.verb = 'answered_question' or
          v.verb = 'commented' or
          v.verb = 'visited_pinboard' or
          v.verb = 'visited_question' or
          v.verb = 'toggled_subscription')
     group by e.user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.survey_submissions(course_uuid, user_uuids = nil)
    s1 = "select e.user_uuid, count(*) as survey_submissions_metric
      from events as e, verbs as v
      where e.verb_id = v.id "
    s2 = course_uuid.present? ? " and in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = " and v.verb = 'submitted_quiz'
      and in_context->>'quiz_type' = 'survey'
      group by e.user_uuid"
    s1 + s2 + s3 + s4
  end

  def self.course_performance(course_uuid, user_uuids = nil)
    s1 = "select user_uuid, max(
      (in_context->>'points_achieved')::float /
      (in_context->>'points_maximal')::float
      ) as course_performance_metric
     from events e, verbs v
     where e.verb_id = v.id "
    s2 = course_uuid.present? ? " and in_context->>'course_id' = '#{course_uuid}' " : ''
    s3 = user_uuids.present? ? userfilter_query(user_uuids, append_and: true) : ''
    s4 = " and v.verb = 'completed_course'
     group by user_uuid"
    s1 + s2 + s3 + s4
  end
end
