# frozen_string_literal: true

module Lanalytics
  module Metric
    class TopCountries < ExpEventsElasticMetric
      include Lanalytics::Helper::PercentageHelper

      description 'Returns users per country.'

      optional_parameter :course_id, :start_date, :end_date

      # rubocop:disable Metric/BlockLength
      exec do |params|
        course_id = params[:course_id]

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [
                  {exists: {field: 'in_context.user_location_country_code'}},
                  {wildcard: {verb: 'visited_*'}},
                ].append(
                  course_filter(course_id),
                  date_filter(params[:start_date], params[:end_date]),
                ).compact,
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
        total_users = result.dig('aggregations', 'ucount', 'value')
        result.dig('aggregations', 'countries', 'buckets').each do |item|
          result_sub_item = {
            country_code: item['key'],
            country_code_iso3: IsoCountryCodes.find(item['key'])&.alpha3,
            distinct_users: item.dig('ucount', 'value'),
            relative_users: item.dig('ucount', 'value').percent_of(total_users),
          }
          processed_result.append(result_sub_item)
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
