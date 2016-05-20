module Lanalytics
  module Processing
    module Transformer
      class WebAnalyticsDataSchemaTransformer < TransformStep
        def transform(original_event, processing_units, load_commands, pipeline_ctx)
          processing_units.each do |punit|
            #From mails we get/support:  tracking-user, tracking-type, tracking-campaign tracking-id
            entity = Lanalytics::Processing::LoadORM::Entity.create(:referral) do
              with_attribute :referrer, :string, punit[:referrer] if punit[:referrer].present?
              with_attribute :referrer_page, :string, punit[:referrer_page] if punit[:referrer_page].present?
              with_attribute :course_id, :uuid, punit[:course_id] if punit[:course_id].present?
              with_attribute :user_id, :uuid, punit[:user_id] if punit[:user_id].present?
              with_attribute :user_id, :uuid, punit[:tracking_user] if punit[:tracking_user].present?
              with_attribute :timestamp, :timestamp, punit[:created_at].present? ? punit[:created_at] : DateTime.now
              with_attribute :tracking_campaign, :uuid, punit[:tracking_campaign] if punit[:tracking_campaign].present?
              with_attribute :tracking_id, :uuid, punit[:tracking_camp] if punit[:tracking_campaign].present?
              with_attribute :tracking_type, :string, punit[:tracking_type] if punit[:tracking_type].present?
            end

            load_commands << Lanalytics::Processing::LoadORM::CreateCommand.with(entity)
          end
        end

      end
    end
  end
end
