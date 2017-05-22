module Lanalytics
  module Metric
    class ActiveUserCountRelative < ExpApiMetric

      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)

        # calculates the (time-dependant) activity (active users) of courses relative to all other courses on the platform (max = 100, min = 0/not present)
        # if course_id present return only one value

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

        max_value = active_users.values.max
        min_value = active_users.values.min

        result = {}
        active_users.each do |id, value|
          if max_value == 0 # should not be possible
            result[id] = 0
          elsif max_value == min_value
            result[id] = 100
          else
            result[id] = ((value - min_value).to_f / (max_value - min_value).to_f) * 100.0
          end
        end

        if course_id.present?
          result[course_id] || 0
        else
          result
        end

      end
    end
  end
end
