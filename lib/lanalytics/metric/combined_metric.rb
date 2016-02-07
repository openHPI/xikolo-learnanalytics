module Lanalytics
  module Metric
    class CombinedMetric
      def self.query(user_id, course_id, start_time, end_date, resource_id, page, per_page)
        results = query_dependent(user_id, course_id, start_time, end_date, resource_id)

        {count: results.values.sum}
      end

      def self.query_dependent(user_id, course_id, start_time, end_date, resource_id)
        dependent_metrics.each_with_object({}) do |metric, results|
          results[metric[:class].name.demodulize] = metric[:class].query(
            user_id,
            course_id,
            start_time,
            end_date,
            resource_id,
            nil,
            nil)[:count] * (metric[:weight] || 1)
        end
      end

      def self.dependent_metrics
        []
      end
    end
  end
end
