module Lanalytics
  module Metric
    class TopCountriesEs < ExpApiMetric

      description 'Returns top 100 countries.'

      optional_parameter :course_id

      exec do |params|
        course_id = params[:course_id]

        # array of mobile runtimes
        mobile_runtimes = %w(Android iOS)

        mobile_conditions = mobile_runtimes.map do |runtime|
          { match: { 'in_context.runtime' => runtime } }
        end

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
              size: 0,
              query: {
                  bool: {
                      must: all_filters(nil, course_id, nil)
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
                          },
                          mobile: {
                              filter: {
                                  bool: {
                                      must: { exists: { field: 'in_context.runtime' } },
                                      should: mobile_conditions,
                                      minimum_should_match: 1
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
              }
          }
        end

        processed_result = []
        # process result
        result['aggregations']['countries']['buckets'].each do |item|
          begin
            result_subitem = {}
            result_subitem[:country_code] = item['key']
            result_subitem[:country_code_iso3] = IsoCountryCodes.find(item['key']).alpha3
            result_subitem[:total_activity] = item['doc_count']
            result_subitem[:distinct_users] = item['ucount']['value']
            result_subitem[:activity_per_user] = item['ucount']['value'] != 0 ? item['doc_count'] / item['ucount']['value'] : 0
            result_subitem[:mobile_users] = item['mobile']['count']['value']
            result_subitem[:mobile_usage] = item['ucount']['value'] != 0 ? item['mobile']['count']['value'].to_f / item['ucount']['value'].to_f : 0
            processed_result << result_subitem
          rescue IsoCountryCodes::UnknownCodeError
          end
        end
        processed_result.sort_by { |i| i[:distinct_users] }.reverse
      end

    end
  end
end
