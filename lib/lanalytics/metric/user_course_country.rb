module Lanalytics
  module Metric
    class UserCourseCountry < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
              size: 0,
              query: {
                  bool: {
                      must: [
                          {
                              match: {
                                  "in_context.course_id" => course_id
                              }
                          },
                          {
                              match: {
                                  "user.resource_uuid" => resource_id
                              }
                          }

                      ]
                  }
              },
              aggregations: {
                  countries: {
                      terms: {
                          field: "in_context.user_location_country_code",
                          size:1
                      },
                  }
              }
          }
        end
        if result['aggregations']['countries']['buckets'][0].present?
          return result['aggregations']['countries']['buckets'][0]['key']
        else
          return []
        end
      end
    end
  end
end