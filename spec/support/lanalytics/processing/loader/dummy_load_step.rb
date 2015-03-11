module Lanalytics
  module Processing
    module Loader
      class DummyLoadStep < LoadStep
        def initialize(datasource = nil)
          @datasource = nil
        end
      end
    end
  end
end