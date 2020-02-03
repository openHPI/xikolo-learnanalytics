# frozen_string_literal: true

module Lanalytics
  module Metric
    class TopCountriesGa < GoogleAnalyticsMetric
      include Lanalytics::Helper::PercentageHelper

      description 'Returns users per country.'

      optional_parameter :course_id

      # rubocop:disable Metric/BlockLength
      exec do |params|
        result = request_report({
          date_ranges: date_ranges,
          dimensions: [
            {name: 'ga:countryIsoCode'},
          ],
          metrics: [
            {expression: 'ga:users'},
          ],
          dimension_filter_clauses: [
            course_filter(params[:course_id]),
          ],
          filters_expression: 'ga:countryIsoCode!=(not set)',
          order_bys: [{
            field_name: 'ga:users',
            sort_order: 'DESCENDING',
          }],
        }, {limit: 250})

        total_users = result[:totals]['ga:users']
        result[:rows].map do |row|
          {
            country_code: row['ga:countryIsoCode'].downcase,
            country_code_iso3: IsoCountryCodes.find(row['ga:countryIsoCode'])
              .alpha3,
            distinct_users: row['ga:users'],
            relative_users: row['ga:users'].percent_of(total_users),
          }
        # rubocop:disable Lint/HandleExceptions
        rescue IsoCountryCodes::UnknownCodeError
          # ignored
        end.compact
      end
      # rubocop:enable all
    end
  end
end
