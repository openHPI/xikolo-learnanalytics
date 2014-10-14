module Lanalytics
  module Filter
    class DataFilter 
      def filter(original_resource_as_hash, processed_resource)
        raise NotImplementedError("This method has to be implemented in the subclass!")
      end
    end
  end
end
