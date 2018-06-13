module Lanalytics
  module Metric
    class FallbackMetric < Base

      def self.datasource_keys
        alt_metrics.flat_map{ |metric| metric.datasource_keys }.uniq
      end

      def self.available?
        datasources.any?{ |ds| ds.present? && ds.ping }
      end

      def self.alt_metrics
        @alt_metrics ||= []
      end

      def self.alternative_metrics(*metrics)
        @alt_metrics = metrics

        description alt_metrics.first.desc

        @exec = proc do |params|
          best_available_metric = alt_metrics.select{ |metric| metric.available? }.first
          if best_available_metric.present?
            result = best_available_metric.query(params)
            @preprocessor.call(result, best_available_metric) if @preprocessor.is_a? Proc
          end
        end
      end

      def self.process_result(&block)
        @preprocessor = block
      end

      def self.required_params
        alt_metrics.flat_map(&:required_params).uniq
      end

      def self.optional_params
        alt_metrics.flat_map(&:optional_params).uniq
      end

    end
  end
end