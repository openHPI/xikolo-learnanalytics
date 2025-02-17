# frozen_string_literal: true

module Lanalytics
  module Metric
    class ActiveUserCountRelative < ExpEventsElasticMetric
      description "
Calculates activity compared to the platform and itself for the last day.
Result if course_id present:
  - relative: percentage of active users compared to total platform activity
  - top: rank of course by active users
  - deviation: deviation of avg active users on platform
  - kpi_activity: activity_today / avg_activity_of_course

Default active users of last day.
".strip

      optional_parameter :start_date, :end_date, :course_id

      exec do |params|
        start_date = params[:start_date]
        end_date = params[:end_date]
        course_id = params[:course_id]

        start_date = start_date.present? ? DateTime.parse(start_date) : 1.day.ago
        end_date = end_date.present? ? DateTime.parse(end_date) : DateTime.now

        active_users = {}

        result = datasource.exec do |client|
          body = {
            size: 0,
            query: {
              bool: {
                filter: {
                  range: {
                    timestamp: {
                      gte: start_date.iso8601,
                      lte: end_date.iso8601,
                    },
                  },
                },
              },
            },
            aggs: {
              courses: {
                terms: {
                  field: 'in_context.course_id',
                  size: 1000,
                },
                aggs: {
                  distinct_user_count: {
                    cardinality: {
                      field: 'user.resource_uuid',
                    },
                  },
                },
              },
            },
          }
          client.search(index: datasource.index, body:)
        end

        result['aggregations']['courses']['buckets'].each do |course|
          active_users[course['key']] = course['distinct_user_count']['value']
        end

        total_activity = active_users.values.sum

        relative_users = {}

        active_users.each do |id, value|
          relative_users[id] = value.to_f / total_activity
        end

        next relative_users if course_id.blank?

        result = {}
        result[:relative] = (relative_users[course_id] || 0).round(2)
        result[:top] = result[:relative] == 0 ? 0 : relative_users.values.sort.reverse.find_index(result[:relative]) + 1
        active_courses = relative_users.size
        result[:deviation] = active_courses == 0 ? 0 : (result[:relative] - (1.0 / active_courses.to_f)).round(2)
        course = Restify.new(:course).get.value!
          .rel(:courses).get({id: course_id}).value!
        start_date = DateTime.parse(course[0]['start_date'])
        days_since_start = (DateTime.now.to_date - start_date.to_date).to_i

        if days_since_start <= 0
          result[:kpi_activity] = nil
        else
          avg_activity_per_day = CourseActivity.query(course_id:, start_date: start_date.to_s,
            end_date: (start_date + days_since_start.day).to_s)[:count].to_f / days_since_start
          activity_today = CourseActivity.query(course_id:, start_date: (DateTime.now - 1.day).to_s,
            end_date: DateTime.now.to_s)[:count].to_f
          result[:kpi_activity] = (avg_activity_per_day == 0 ? 0 : activity_today / avg_activity_per_day).round(2)
        end

        result
      end
    end
  end
end
