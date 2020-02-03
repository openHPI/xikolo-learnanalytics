# frozen_string_literal: true

module Lanalytics
  module Metric
    class TopCountriesEs < ExpEventsElasticMetric
      include Lanalytics::Helper::PercentageHelper

      description 'Returns users per country.'

      optional_parameter :course_id

      # rubocop:disable Metric/BlockLength
      exec do |params|
        course_id = params[:course_id]

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: all_filters(nil, course_id, nil),
              },
            },
            aggregations: {
              ucount: {
                cardinality: {
                  field: 'user.resource_uuid',
                },
              },
              countries: {
                terms: {
                  field: 'in_context.user_location_country_code',
                  size: 250,
                },
                aggregations: {
                  ucount: {
                    cardinality: {
                      field: 'user.resource_uuid',
                    },
                  },
                },
              },
            },
          }
        end

        processed_result = []
        # process result
        total_users = result['aggregations']['ucount']['value']
        result['aggregations']['countries']['buckets'].each do |item|
          result_subitem = {}
          result_subitem[:country_code] = item['key']
          result_subitem[:country_code_iso3] = IsoCountryCodes.find(item['key'])
            .alpha3
          result_subitem[:distinct_users] = item['ucount']['value']
          result_subitem[:relative_users] = result_subitem[:distinct_users]
            .percent_of(total_users)
          processed_result << result_subitem
        # rubocop:disable Lint/HandleExceptions
        rescue IsoCountryCodes::UnknownCodeError
          # ignored
        end
        processed_result.sort_by {|i| i[:distinct_users] }.reverse
      end
      # rubocop:enable all
    end
  end
end
