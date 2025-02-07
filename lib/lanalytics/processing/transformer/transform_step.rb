# frozen_string_literal: true

module Lanalytics
  module Processing
    module Transformer
      class TransformStep
        def transform(_original_event, _processing_units, _load_commands, _pipeline_ctx)
          raise NotImplementedError.new 'This method has to be implemented in the subclass!'
        end
      end
    end
  end
end
