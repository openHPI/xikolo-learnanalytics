# frozen_string_literal: true

module Lanalytics
  module Processing
    module Extractor
      class AmqEventExtractor < ExtractStep
        def initialize(type = nil)
          @type = type
        end

        def extract(original_event, processing_units, _pipeline_ctx)
          processing_units << Lanalytics::Processing::Unit.new(@type, original_event)
        end
      end
    end
  end
end
