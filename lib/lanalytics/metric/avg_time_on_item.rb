module Lanalytics
  module Metric
    class AvgTimeOnItem < GoogleAnalyticsMetric

      description 'The average time users stay on a certain item (in seconds).'

      required_parameter :item_id

      exec do |params|
        result = request_report({
            date_ranges: date_ranges,
            metrics: [
              { expression: 'ga:pageviews' },
              { expression: 'ga:avgTimeOnPage' }
            ],
            dimension_filter_clauses: [
              item_filter(params[:item_id])
            ]
        })

        row = result[:rows][0]
        {
          total_visits: row['ga:pageviews'],
          avg_time_on_item: row['ga:avgTimeOnPage']
        }
      end

    end
  end
end