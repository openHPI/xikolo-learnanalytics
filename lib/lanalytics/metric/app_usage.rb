module Lanalytics
  module Metric
    class AppUsage < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)

        # array of app runtimes
        app_runtimes = %w(Android iOS)

        app_conditions = []

        app_runtimes.each do |runtime|
          app_conditions << { match: { 'in_context.runtime' => runtime } }
        end

        # build conditions for query
        conditions = []

        if course_id.present?
          conditions << { match: { 'in_context.course_id' => course_id } }
        end

        if resource_id.present?
          conditions << { match: { 'resource.resource_uuid' => resource_id } }
        end

        conditions << { exists: { field: 'in_context.runtime' }}

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
              size: 0,
              query: {
                  bool: {
                      must: conditions
                  }
              },
              aggs: {
                user_count: {
                  cardinality: {
                      field: 'user.resource_uuid'
                  }
                },
                app_count: {
                  filter: {
                      bool: {
                          should: app_conditions
                      }
                  },
                  aggs: {
                      count: {
                          cardinality: {
                              field: 'user.resource_uuid'
                          }
                      }
                  }
                },
                web_count: {
                  filter: {
                      bool: {
                          must_not: app_conditions
                      }
                  },
                  aggs: {
                      count: {
                          cardinality: {
                              field: 'user.resource_uuid'
                          }
                      }
                  }
                }
              }
          }

        end

        processed_result = {}
        processed_result[:user_count] = result['aggregations']['user_count']['value']
        processed_result[:web_count] = result['aggregations']['web_count']['count']['value']
        processed_result[:app_count] = result['aggregations']['app_count']['count']['value']
        processed_result[:mixed_count] = processed_result[:app_count] + processed_result[:web_count] - processed_result[:user_count]
        return processed_result
      end
    end
  end
end