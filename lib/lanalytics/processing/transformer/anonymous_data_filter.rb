module Lanalytics
  module Processing
    module Transformer
      class AnonymousDataFilter < TransformStep

        def transform(_original_event, processing_units, _load_commands, _pipeline_ctx)
          processing_units.each do |processing_unit|
            processing_unit.data.delete_if { |key, _value| symbol_anonymous?(key) }
          end
        end

        private

        def symbol_anonymous?(symbol)
          symbol[/(mail)|(email)|(name)|(password)/].present?
        end

      end
    end
  end
end
