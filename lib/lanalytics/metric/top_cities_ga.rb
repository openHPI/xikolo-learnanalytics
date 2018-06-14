module Lanalytics
  module Metric
    class TopCitiesGa < GoogleAnalyticsMetric
      include Lanalytics::Helper::PercentageHelper

      description 'Returns top 100 cities.'

      optional_parameter :course_id

      exec do |params|
        result = request_report({
          date_ranges: date_ranges,
          dimensions: [
            { name: 'ga:city' },
            { name: 'ga:countryIsoCode' }
          ],
          metrics: [
            { expression: 'ga:users' }
          ],
          dimension_filter_clauses: [
            course_filter(params[:course_id])
          ],
          filters_expression: 'ga:city!=(not set)',
          order_bys: [{
            field_name: 'ga:users',
            sort_order: 'DESCENDING'
          }]
        }, limit: 100)

        total_users = result[:totals]['ga:users']
        result[:rows].map do |row|
          begin
            {
              city_name: row['ga:city'],
              country_code: row['ga:countryIsoCode'].downcase,
              country_code_iso3: IsoCountryCodes.find(row['ga:countryIsoCode']).alpha3,
              distinct_users: row['ga:users'],
              relative_users: row['ga:users'].percent_of(total_users)
            }
          rescue IsoCountryCodes::UnknownCodeError
          end
        end.compact
      end

    end
  end
end