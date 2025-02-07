# frozen_string_literal: true

module Lanalytics
  module Processing
    module Extractor
      class ExtractStep
        def extract(_original_event, _processing_units, _pipeline_ctx)
          raise NotImplementedError.new 'This method has to be implemented in the subclass!'
        end
      end
    end
  end
end
