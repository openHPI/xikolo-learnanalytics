# frozen_string_literal: true

module Lanalytics
  module Metric
    class TopCities < ExpEventsElasticMetric
      include Lanalytics::Helper::PercentageHelper

      description 'Returns users per city (top 100 cities).'

      optional_parameter :course_id, :start_date, :end_date

      exec do |params|
        course_id = params[:course_id]

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [
                  {exists: {field: 'in_context.user_location_country_code'}},
                  {exists: {field: 'in_context.user_location_city'}},
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
              cities: {
                terms: {
                  script:
                    'doc["in_context.user_location_country_code"].value ' \
                    '+ ":" + ' \
                    'doc["in_context.user_location_city"].value',
                  size: 100,
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
        result.dig('aggregations', 'cities', 'buckets').each do |item|
          country_code, city_name = item['key'].split(':')
          result_sub_item = {
            city_name: city_name&.titleize,
            country_code:,
            country_code_iso3: IsoCountryCodes.find(country_code)&.alpha3,
            distinct_users: item.dig('ucount', 'value'),
            relative_users: item.dig('ucount', 'value').percent_of(total_users),
          }
          processed_result.append(result_sub_item)
        # rubocop:disable Lint/HandleExceptions
        rescue IsoCountryCodes::UnknownCodeError
          # ignored
        end
        # rubocop:enable all
        processed_result.sort_by {|i| i[:distinct_users] }.reverse
      end
    end
  end
end
