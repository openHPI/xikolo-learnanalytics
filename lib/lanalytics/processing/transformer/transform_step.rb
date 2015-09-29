module Lanalytics
  module Processing
    module Transformer

      class TransformStep
        def transform(original_event, processing_units, load_commands, pipeline_ctx)
          raise NotImplementedError.new 'This method has to be implemented in the subclass!'
        end
      end

    end
  end
end
