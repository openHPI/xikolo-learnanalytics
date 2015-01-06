module Lanalytics
  module Processing
    module Loader

      class LoadStep
        attr_reader :datasource

        def initialize(datasource = nil)
          # Needs to be taken care of in the child class
          raise NotImplementedError("This method has to be implemented in the subclass!")
        end

        def load(processing_units, load_commands, pipeline_ctx)
          raise NotImplementedError("This method has to be implemented in the subclass!")
        end
      end

    end
  end
end
