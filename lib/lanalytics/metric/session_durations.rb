module Lanalytics
  module Metric
    class SessionDurations < GoogleAnalyticsMetric

      description 'The total and average session duration.'

      optional_parameter :start_date, :end_date, :course_id

      exec do |params|
        result = request_report({
          date_ranges: date_ranges(params[:start_date], params[:end_date]),
          metrics: [
            { expression: 'ga:sessions' },
            { expression: 'ga:sessionDuration' },
            { expression: 'ga:avgSessionDuration' }
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

        row = result[:rows].first
        {
            total_sessions: row['ga:sessions'],
            total_session_duration: row['ga:sessionDuration'],
            avg_session_duration: row['ga:avgSessionDuration']
        }
      end
    end
  end
end