module Lanalytics
  module Metric

    class << self

      def resolve(name)
        "Lanalytics::Metric::#{name.camelize}".constantize if all.include? name.camelize
      end

      def all
        Rails.root.join('lib/lanalytics/metric')
          .to_enum(:each_child)
          .map { |i| i.basename.to_s.split('.').first.camelize }
          .sort
          .reject { |c| %w(Base ExpApiMetric ExpApiCountMetric CombinedMetric ReferrerMetric).include? c }
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
            raise ArgumentError, "Required parameter missing. Required: [#{required_params.join(', ')}]. Received: [#{params.keys.join(', ')}]."
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

      end

    end
  end
end
