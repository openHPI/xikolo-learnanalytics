module Lanalytics
  module Metric
    class DaysSinceLastSession < GoogleAnalyticsMetric
      include Lanalytics::Helper::PercentageHelper
      extend Lanalytics::Helper::GoogleAnalyticsBucketHelper

      description 'The number of sessions broken down to the number of days since last session'

      optional_parameter :start_date, :end_date, :course_id

      exec do |params|
        bucket_boundaries = [0, 1, 2, 3, 4, 5, 6, 7, 14, 30, 60]
        buckets_labels = histogram_bucket_labels bucket_boundaries

        result = request_report({
          date_ranges: date_ranges(params[:start_date], params[:end_date]),
          dimensions: [
            {
              name: 'ga:daysSinceLastSession',
              histogram_buckets: bucket_boundaries
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

        processed_result = { buckets: [] }

        total_sessions = result[:totals]['ga:sessions']
        unless total_sessions.zero?
          bucket_sessions = result[:rows].map{ |row| [row['ga:daysSinceLastSession'], row['ga:sessions'] ] }.to_h
          processed_result[:buckets] = buckets_labels.map do |bucket_label|
            sessions = bucket_sessions[bucket_label].nil? ? 0 : bucket_sessions[bucket_label]
            {
              days_since_last_session: bucket_label,
              total_sessions: sessions,
              relative_sessions: sessions.percent_of(total_sessions)
            }
          end
        end

        processed_result
      end
    end
  end
end
