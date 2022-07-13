# frozen_string_literal: true

module Lanalytics
  module Processing
    module Transformer
      class AnonymousDataFilter < TransformStep
        def transform(_original_event, processing_units, _load_commands, _pipeline_ctx)
          processing_units.each do |processing_unit|
            filter_anonymous_data processing_unit.data
            if processing_unit[:in_context].present?
              filter_anonymous_data processing_unit.data[:in_context]
            end
          end
        end

        private

        def filter_anonymous_data(hash)
          hash.delete_if {|key, _value| symbol_anonymous?(key) }
        end

        def symbol_anonymous?(symbol)
          symbol[/(mail)|(email)|(name)|(password)|(user_ip)|(user_agent)/].present?
        end
      end
    end
  end
end
