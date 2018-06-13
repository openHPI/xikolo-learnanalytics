module Lanalytics
  module Metric
    class ActiveUsersByDaytime < GoogleAnalyticsMetric

      description 'Counts the number of activities per day of week and hour'

      required_parameter :start_date, :end_date

      optional_parameter :course_id, :item_id

      exec do |params|
        day_of_week_report, hour_report, combined_report = request_reports([
          active_users_report_request(params, %w(ga:dayOfWeek)),
          active_users_report_request(params, %w(ga:hour)),
          active_users_report_request(params, %w(ga:dayOfWeek ga:hour))
        ])

        processed_result = {}

        # Get date range to compute averages
        start_date = [params[:start_date].to_date, datasource.adoption_date].max
        end_date = params[:end_date].to_date
        date_range = (start_date..end_date).to_a

        # Process days
        processed_result[:day_of_weeks] = combined_report[:rows].group_by{ |row| row['ga:dayOfWeek'] }.map do |day_of_week, rows|
          day_of_week_count = date_range.select{ |date| date.wday == day_of_week.to_i }.size
          day_row = day_of_week_report[:rows].find{ |row| row['ga:dayOfWeek'] == day_of_week }
          {
            day_of_week: day_of_week.to_i,
            avg_users: (day_row['ga:users'] / day_of_week_count).round(2),
            hours: rows.map do |row|
              {
                hour: row['ga:hour'].to_i,
                avg_users: (row['ga:users'] / day_of_week_count).round(2)
              }
            end
          }
        end

        # Process hours
        processed_result[:hours] = hour_report[:rows].group_by{ |row| row['ga:hour'] }.map do |hour, rows|
          hour_total_users = rows.map{ |row| row['ga:users'] }.sum
          {
            hour: hour,
            avg_users: (hour_total_users / date_range.size).round(2)
          }
        end

        processed_result
      end

      def self.active_users_report_request(params, dimension_names)
        {
          date_ranges: date_ranges(params[:start_date], params[:end_date]),
          dimensions: dimension_names.map{ |name| { name: name } },
          metrics: [
            { expression: 'ga:users' }
          ],
          dimension_filter_clauses: [
            course_filter(params[:course_id]),
            item_filter(params[:item_id]),
            # Exclude completed_course events as they are not triggered by an action of a user
            {
              operator: 'AND',
              filters: [{
                dimension_name: 'ga:eventAction',
                not: true,
                operator: 'EXACT',
                expressions: ['completed_course']
              }]
            }
          ]
        }
      end

    end
  end
end
