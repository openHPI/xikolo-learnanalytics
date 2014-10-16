module Lanalytics
  module Processor
    class LoggerProcessor < Lanalytics::Processor::DataProcessor
      def process(original_resource_as_hash, processed_resource)
        puts processed_resource.to_s
      end
    end
  end
end
