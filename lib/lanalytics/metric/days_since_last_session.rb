module Lanalytics
  module Metric
    class DaysSinceLastSession < GoogleAnalyticsMetric
      include Lanalytics::Helper::PercentageHelper

      description 'The number of sessions broken down to the number of days since last session'

      optional_parameter :start_date, :end_date, :course_id

      exec do |params|
        result = request_report({
          date_ranges: date_ranges(params[:start_date], params[:end_date]),
          dimensions: [
            {
              name: 'ga:daysSinceLastSession',
              histogram_buckets: [0, 1, 2, 3, 4, 5, 6, 7, 14, 30, 60]
            }
          ],
          metrics: [
            { expression: 'ga:sessions' }
          ],
          dimension_filter_clauses: [
            course_filter(params[:course_id]),
            # Exclude service events as they are handled as new, separate sessions
            {
              filters: [{
                dimension_name: 'ga:dataSource',
                not: true,
                operator: 'EXACT',
                expressions: ['service']
              }]
            }
          ]
        })

        processed_result = {}

        total_sessions = result[:totals]['ga:sessions']
        processed_result[:buckets] = result[:rows].map do |row|
          {
            days_since_last_session: row['ga:daysSinceLastSession'],
            total_sessions: row['ga:sessions'],
            relative_sessions: row['ga:sessions'].percent_of(total_sessions)
          }
        end

        processed_result
      end
    end
  end
end
