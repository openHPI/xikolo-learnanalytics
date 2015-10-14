module Lanalytics
  module Processing
    module Transformer
      class WebAnalyticsDataSchemaTransformer < TransformStep

        def transform(original_event, processing_units, load_commands, pipeline_ctx)
          processing_units.each do |punit|
            next unless punit[:referrer_url]

            entity = Lanalytics::Processing::LoadORM::Entity.create(:referral) do
              with_attribute :referrer, :string, punit[:referrer_url]
              with_attribute :referred_page, :string, punit[:referrer_page]
              with_attribute :course_id, :uuid, punit[:course_id] if punit[:course_id]
              with_attribute :user_id, :uuid, punit[:user_id] if punit[:user_id]
              with_attribute :timestamp, :timestamp, punit[:created_at]
            end

            load_commands << Lanalytics::Processing::LoadORM::CreateCommand.with(entity)
          end
        end

      end
    end
  end
end
