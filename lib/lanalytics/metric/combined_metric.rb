module Lanalytics
  module Metric
    class CombinedMetric
      def self.query(user_id, course_id, start_time, end_date)
        results = query_dependent(user_id, course_id, start_time, end_date)

        {count: results.values.sum}
      end

      def self.query_dependent(user_id, course_id, start_time, end_date)
        dependent_metrics.each_with_object({}) do |metric, results|
          results[metric[:class].name.demodulize] = metric[:class].query(
            user_id,
            course_id,
            start_time,
            end_date)[:count] * (metric[:weight] || 1)
        end
      end

      def self.dependent_metrics
        []
      end
    end
  end
end
