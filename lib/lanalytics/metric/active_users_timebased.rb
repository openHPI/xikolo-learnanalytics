module Lanalytics
  module Metric
    class ActiveUsersTimebased < GoogleAnalyticsMetric
      include Lanalytics::Helper::PercentageHelper

      description 'Counts the number of activities per day and hour'

      required_parameter :start_date, :end_date

      optional_parameter :course_id, :item_id

      exec do |params|
        result = request_report({
          date_ranges: date_ranges(params[:start_date], params[:end_date]),
          dimensions: [
            { name: 'ga:date' },
            { name: 'ga:hour' },
          ],
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
        })

        processed_result = {}

        # Total values
        total_users = result[:totals]['ga:users']

        # Process days
        processed_result[:days] = result[:rows].group_by{ |row| row['ga:date'] }.map do |date, rows|
          day_total_users = rows.map{ |row| row['ga:users'] }.sum
          {
            date: date,
            total_users: day_total_users,
            relative_users: day_total_users.percent_of(total_users),
            hours: rows.map do |row|
              {
                hour: row['ga:hour'].to_i,
                total_users: row['ga:users'],
                relative_users: row['ga:users'].percent_of(day_total_users)
              }
            end
          }
        end

        processed_result
      end

    end
  end
end
