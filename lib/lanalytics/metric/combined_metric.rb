module Lanalytics
  module Metric
    class CombinedMetric < Base
      def self.datasource_keys
        dep_metrics.flat_map {|metric| metric[:class].datasource_keys }.uniq
      end

      def self.query_dependent(**params)
        dep_metrics.each_with_object({}) do |metric, results|
          results[metric[:class].name.demodulize] = metric[:class].query(params)[:count] * (metric[:weight] || 1)
        end
      end

      def self.dep_metrics
        @dep_metrics ||= []
      end

      def self.dependent_metrics(metrics)
        @dep_metrics = metrics

        description("Combines the following metrics: #{dep_metrics.map {|metric|
          "#{metric[:class].name.demodulize.underscore} (#{metric[:weight] || 1})"
        }.join(', ')}.")

        @exec = proc do |params|
          results = query_dependent(params)
          {count: results.values.sum}
        end
      end

      def self.required_params
        dep_metrics.flat_map {|metric| metric[:class].required_params }.uniq
      end

      def self.optional_params
        dep_metrics.flat_map {|metric| metric[:class].optional_params }.uniq
      end
    end
  end
end
