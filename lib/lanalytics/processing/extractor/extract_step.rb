module Lanalytics
  module Processing
    module Extractor

      class ExtractStep
        def extract(original_event, processing_units, pipeline_ctx)
          raise NotImplementedError.new 'This method has to be implemented in the subclass!'
        end
      end

    end
  end
end
