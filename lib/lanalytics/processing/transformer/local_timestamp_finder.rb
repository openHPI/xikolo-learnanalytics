module Lanalytics
  module Processing
    module Transformer

      class LocalTimestampFinder < TransformStep

        def transform(original_event, processing_units, load_commands, pipeline_ctx)
          processing_units.each do | processing_unit |
            next if processing_unit[:in_context].nil?
            next if processing_unit[:in_context][:user_location_latitude].nil?
            next if processing_unit[:in_context][:user_location_longitude].nil?

            timezone = Timezone::Zone.new latlon: [
              processing_unit[:in_context][:user_location_latitude],
              processing_unit[:in_context][:user_location_longitude]
            ]

            processing_unit[:in_context][:user_local_timestamp] = (timezone.time Time.now).iso8601
          end
        end

      end

    end
  end
end

