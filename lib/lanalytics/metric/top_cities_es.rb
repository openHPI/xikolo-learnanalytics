module Lanalytics
  module Metric
    class TopCitiesEs < ExpApiMetric
      include Lanalytics::Helper::PercentageHelper

      description 'Returns top 100 cities.'

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
                  ucount: {
                      cardinality: {
                          field: 'user.resource_uuid'
                      }
                  },
                  with_city: {
                      filter: {
                          bool: {
                              must: [
                                  { exists: { field: 'in_context.user_location_country_code' } },
                                  { exists: { field: 'in_context.user_location_city' } }
                              ],
                              must_not: [
                                  { term: { 'in_context.user_location_country_code': '' } },
                                  { term: { 'in_context.user_location_city': '' } }
                              ]
                          }
                      },
                      aggregations: {
                          city_country: {
                              terms: {
                                  script: 'doc["in_context.user_location_country_code"].value + ":" + doc["in_context.user_location_city"].value',
                                  size: 100
                              },
                              aggregations: {
                                  cities: {
                                      terms: {
                                          field: 'in_context.user_location_city'
                                      },
                                      aggregations: {
                                          countries: {
                                              terms: {
                                                  field: 'in_context.user_location_country_code'
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
                              }
                          }
                      }
                  }
              }
          }
        end

        processed_result = []
        # process result
        total_users = result['aggregations']['ucount']['value']
        result['aggregations']['with_city']['city_country']['buckets'].each do |bucket_item|
          city_item = bucket_item['cities']['buckets'].first
          country_item = city_item['countries']['buckets'].first
          begin
            result_subitem = {}
            result_subitem[:city_name] = city_item['key'].capitalize
            result_subitem[:country_code] = country_item['key']
            result_subitem[:country_code_iso3] = IsoCountryCodes.find(country_item['key']).alpha3
            result_subitem[:total_activity] = country_item['doc_count']
            result_subitem[:distinct_users] = country_item['ucount']['value']
            result_subitem[:relative_users] = result_subitem[:distinct_users].percent_of(total_users)
            result_subitem[:activity_per_user] = country_item['ucount']['value'] != 0 ? country_item['doc_count'] / country_item['ucount']['value'] : 0
            result_subitem[:mobile_users] = country_item['mobile']['count']['value']
            result_subitem[:mobile_usage] = country_item['ucount']['value'] != 0 ? country_item['mobile']['count']['value'].to_f / country_item['ucount']['value'].to_f : 0
            processed_result << result_subitem
          rescue IsoCountryCodes::UnknownCodeError
          end
        end
        processed_result.sort_by { |i| i[:distinct_users] }.reverse
      end

    end
  end
end
