module Lanalytics
  module Metric
    class ActiveUserCountRelative < ExpApiMetric

      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)

        # calculates activity compared to the platform and itself for the last day
        # result if course_id present:
        #   relative: percentage of active users compared to total platform activity
        #   top: rank of course by active users
        #   deviation: deviation of avg active users on platform
        #   kpi_activity: activity_today / avg_activity_of_course

        # default active users of last day

        start_time = (start_time.present? ? DateTime.parse(start_time) : (DateTime.now - 1.day))
        end_time = (end_time.present? ? DateTime.parse(end_time) : (DateTime.now))

        active_users = {}

        result = datasource.exec do |client|
          body = {
            size: 0,
            query: {
              bool: {
                filter: {
                  range: {
                    timestamp: {
                      gte: start_time.iso8601,
                      lte: end_time.iso8601
                    }
                  }
                }
              }
            },
            aggs: {
              courses: {
                terms: {
                  field: 'in_context.course_id',
                  size: 1000
                },
                aggs: {
                  distinct_user_count: {
                    cardinality: {
                      field: 'user.resource_uuid'
                    }
                  }
                }
              }
            }
          }
          client.search index: datasource.index, body: body
        end

        result['aggregations']['courses']['buckets'].each do |course|
          active_users[course['key']] = course['distinct_user_count']['value']
        end

        total_activity = active_users.values.sum

        relative_users = {}

        active_users.each do |id, value|
          relative_users[id] = value.to_f / total_activity.to_f
        end

        if not course_id.present?
          return relative_users
        end

        result = {}
        result[:relative] = (relative_users[course_id] || 0).round(2)
        result[:top] = result[:relative] != 0 ? relative_users.values.sort.reverse.find_index(result[:relative]) + 1 : 0
        active_courses = relative_users.size
        result[:deviation] = active_courses != 0 ? (result[:relative] - (1.0 / active_courses.to_f)).round(2) : 0
        course = Xikolo.api(:course).value!.rel(:courses).get(id: course_id).value!
        start_date = DateTime.parse(course[0].start_date)
        days_since_start = (DateTime.now.to_date - start_date.to_date).to_i

        if days_since_start <= 0
          result[:kpi_activity] = nil
        else
          avg_activity_per_day = CourseActivity.query(nil, course_id, start_date.to_s, (start_date + days_since_start.day).to_s, nil, nil, nil)[:count].to_f / days_since_start.to_f
          activity_today = CourseActivity.query(nil, course_id, (DateTime.now - 1.day).to_s, DateTime.now.to_s, nil, nil, nil)[:count].to_f
          result[:kpi_activity] = (avg_activity_per_day != 0 ? activity_today / avg_activity_per_day : 0).round(2)
        end

        result

      end
    end
  end
end
