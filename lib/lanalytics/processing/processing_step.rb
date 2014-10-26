module Lanalytics
  module Processing

    class ProcessingStep
      def process(original_resource_as_hash, processed_resource, opts = nil)
        raise NotImplementedError("This method has to be implemented in the subclass!")
      end
    end
  
  end
end
