module Lanalytics
  module Metric
    class SessionDurationBuckets < GoogleAnalyticsMetric
      include Lanalytics::Helper::PercentageHelper
      extend Lanalytics::Helper::GoogleAnalyticsBucketHelper

      description 'The number of sessions broken down to buckets of session durations'

      optional_parameter :start_date, :end_date, :course_id

      exec do |params|
        bucket_boundaries = [10, 30, 60, 180, 600, 1800, 3600, 7200]
        bucket_labels = histogram_bucket_labels bucket_boundaries

        result = request_report({
          date_ranges: date_ranges(params[:start_date], params[:end_date]),
          dimensions: [
            {
              name: 'ga:sessionDurationBucket',
              histogram_buckets: [10, 30, 60, 180, 600, 1800, 3600, 7200]
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
        bucket_sessions = result[:rows].map{ |row| [row['ga:sessionDurationBucket'], row['ga:sessions'] ] }.to_h
        processed_result[:buckets] = bucket_labels.map do |bucket_label|
          sessions = bucket_sessions[bucket_label].nil? ? 0 : bucket_sessions[bucket_label]
          {
            duration: bucket_label,
            total_sessions: sessions,
            relative_sessions: sessions.percent_of(total_sessions)
          }
        end

        processed_result
      end

    end
  end
end