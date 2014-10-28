module Lanalytics
  module Processing
    module Processor
      class LoggerProcessor < Lanalytics::Processing::ProcessingStep
        def process(original_resource_as_hash, processed_resource, opts = nil)
          Rails.logger.debug "Processing resources: #{processed_resource.to_s}"
        end
      end
    end
  end
end
