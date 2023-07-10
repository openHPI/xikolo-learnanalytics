# frozen_string_literal: true

module Lanalytics
  module Metric
    class << self
      def resolve(name)
        return nil unless all.include? name.camelize

        "Lanalytics::Metric::#{name.camelize}".constantize
      end

      IGNORED_METRIC_CLASSES = %w[
        Base
        ExpEventsElasticMetric
        ExpEventsCountElasticMetric
        ExpEventsPostgresMetric
        LinkTrackingEventsElasticMetric
        ClusteringMetric
        CombinedMetric
      ].freeze
      def all
        Rails.root.join('lib/lanalytics/metric')
          .to_enum(:each_child)
          .map { _1.basename.to_s.split('.').first.camelize }
          .sort
          .reject { IGNORED_METRIC_CLASSES.include? _1 }
      end
    end

    class Base
      class << self
        attr_reader :desc

        def description(text)
          @desc = text
        end

        def query(**params)
          unless (required_params - params.keys).empty?
            raise ArgumentError.new(
              "Required parameter missing for #{self}. " \
              "Required: [#{required_params.join(', ')}]. " \
              "Received: [#{params.keys.join(', ')}].",
            )
          end

          allowed_params = params.slice(*(required_params + optional_params))

          @exec.call(allowed_params) if @exec.is_a? Proc
        end

        def exec(&block)
          @exec = block
        end

        def required_params
          @required_params ||= []
        end

        def optional_params
          @optional_params ||= []
        end

        def required_parameter(*params)
          @required_params = params
        end

        def optional_parameter(*params)
          @optional_params = params
        end

        def datasource_keys
          @datasource_keys ||= []
        end

        def datasources
          datasource_keys.map do |key|
            Lanalytics::Processing::DatasourceManager.datasource(key)
          end
        end

        def available?
          datasources.all? do |ds|
            ds.present? && Rails.cache.fetch(
              "ds_availability/#{ds.key}/", expires_in: 2.minutes
            ) { ds.ping }
          end
        end
      end
    end
  end
end
