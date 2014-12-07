module Lanalytics
  module Processing
    module Loader

      class LoadStep

        def initialize(data_store_key = nil)
          # Needs to be taken care of in the child class
        end

        def load(processing_units, load_commands, pipeline_ctx)
          raise NotImplementedError("This method has to be implemented in the subclass!")
        end
      end

    end
  end
end
