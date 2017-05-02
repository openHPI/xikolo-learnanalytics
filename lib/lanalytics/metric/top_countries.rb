module Lanalytics
  module Metric
    class TopCountries < ExpApiMetric

      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [
                  { match: { 'in_context.course_id' => course_id } }
                ]
              }
            },
            aggregations: {
              countries: {
                terms: {
                  field: 'in_context.user_location_country_code',
                  size: 100
                },
                aggregations: {
                  ucount: {
                    cardinality: {
                      field: 'user.resource_uuid'
                    }
                  }
                }
              }
            }
          }
        end

        processed_result = []
        #process result
        result['aggregations']['countries']['buckets'].each do |item|
          begin
            result_subitem = {}
            result_subitem[:country_code] = item['key']
            result_subitem[:country_code_iso3] = IsoCountryCodes.find(item['key']).alpha3
            result_subitem[:total_activity] = item['doc_count']
            result_subitem[:distinct_users] = item['ucount']['value']
            processed_result << result_subitem
          rescue IsoCountryCodes::UnknownCodeError
          end
        end
        processed_result.sort_by {|i| i[:distinct_users]}.reverse
      end

    end
  end
end
