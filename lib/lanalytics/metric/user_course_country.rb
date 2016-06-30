module Lanalytics
  module Metric
    class UserCourseCountry < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        self.unescaped_query(user_id, course_id, start_time, end_time, resource_id, page, per_page).to_json
      end

      def self.unescaped_query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        conditions = []
        if course_id.present?
          conditions << {
              match: {
                  "in_context.course_id" => course_id
              }
          }
        end
        if user_id.present?
          conditions << {
              match: {
                  "user.resource_uuid" => user_id
              }
          }
        end
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
              size: 0,
              query: {
                  bool: {
                      must: conditions
                  }
              },
              aggregations: {
                  countries: {
                      terms: {
                          field: "in_context.user_location_country_code",
                          size: 0
                      },
                  }
              }
          }
        end
        if result['aggregations']['countries']['buckets'][0].present?
          return result['aggregations']['countries']['buckets'][0]['key']
        else
          return ''
        end
      end
    end
  end
end