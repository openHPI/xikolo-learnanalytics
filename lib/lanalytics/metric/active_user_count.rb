module Lanalytics
  module Metric
    class ActiveUserCount < ExpApiMetric

      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        result = datasource.exec do |client|
          # default 30 min
          start_time = start_time.present? ? DateTime.parse(start_time) : (DateTime.now - 30.minutes)
          end_time = end_time.present? ? DateTime.parse(end_time) : (DateTime.now)

          body = {
            size: 0,
            query: {
              bool: {
                minimum_should_match: 1,
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
              distinct_user_count: {
                cardinality: {
                  field: 'user.resource_uuid'
                }
              }
            }
          }

          if course_id.present?
            body[:query][:bool][:should] = []
            body[:query][:bool][:should] << { match: { 'in_context.course_id' => course_id } }
            body[:query][:bool][:should] << { match: { 'resource.resource_uuid' => course_id } }
          end

          if resource_id.present?
            courses = Xikolo.api(:course).value!.rel(:courses).get(cat_id: resource_id).value!
            body[:query][:bool][:should] = []
            courses.each do |course|
              body[:query][:bool][:should] << { match: { 'in_context.course_id' => course['id'] } }
              body[:query][:bool][:should] << { match: { 'resource.resource_uuid' => course['id'] } }
            end
          end

          client.search index: datasource.index, body: body
        end

        result['aggregations']['distinct_user_count']['value']
      end

    end
  end
end
