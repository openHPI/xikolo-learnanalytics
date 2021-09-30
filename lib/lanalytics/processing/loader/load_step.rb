# frozen_string_literal: true

module Lanalytics
  module Processing
    module Loader
      class LoadStep
        attr_reader :datasource

        def load(_original_event, _load_commands, _pipeline_ctx)
          raise NotImplementedError.new 'This method has to be implemented in the subclass!'
        end

        def available?
          raise NotImplementedError.new 'This method has to be implemented in the subclass!'
        end
      end
    end
  end
end
