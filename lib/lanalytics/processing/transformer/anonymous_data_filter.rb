module Lanalytics
  module Processing
    module Transformer
      class AnonymousDataFilter < TransformStep

        def transform(original_event, processing_units, load_commands, pipeline_ctx)

          processing_units.each do | processing_unit |
            processing_unit.data.delete_if do |key, value| symbol_anonymous?(key)
            end
          end

        end

        private
        def symbol_anonymous?(symbol)
          %w(mail email name password).each do | dangerous_keyword |
            return true if symbol.to_s.include?(dangerous_keyword)
          end
          return false
        end

      end

    end
  end
end
