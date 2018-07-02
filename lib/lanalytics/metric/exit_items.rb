module Lanalytics
  module Metric
    class ExitItems < GoogleAnalyticsMetric
      include Lanalytics::Helper::PercentageHelper

      description 'Counts the number of session exits per item of a course'

      required_parameter :course_id

      optional_parameter :start_date, :end_date, :item_id

      exec do |params|
        result = request_report({
            date_ranges: date_ranges(params[:start_date], params[:end_date]),
            dimensions: [
                { name: 'ga:dimension2' },
            ],
            metrics: [
                { expression: 'ga:pageviews' },
                { expression: 'ga:exits' },
                { expression: 'ga:exitRate' }
            ],
            dimension_filter_clauses: [
                course_filter(params[:course_id]),
                item_filter(params[:item_id])
            ],
            order_bys: [{
                field_name: 'ga:exitRate',
                sort_order: 'DESCENDING'
            }]
        })

        processed_result = {}
        processed_result[:items] = result[:rows].map do |row|
          {
              item_id: row['ga:dimension2'],
              total_pageviews: row['ga:pageviews'],
              total_exits: row['ga:exits'],
              relative_exits: row['ga:exitRate']
          }
        end

        processed_result
      end

    end
  end
end
