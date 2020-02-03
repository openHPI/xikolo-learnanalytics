# frozen_string_literal: true

# rubocop:disable Metrics/LineLength, Metrics/AbcSize, Metrics/MethodLength
module Lanalytics
  module Processing
    module Transformer
      class LinkTrackingEventElasticSchemaTransformer < TransformStep
        def transform(_, processing_units, load_commands, _)
          processing_units.each do |punit|
            entity = Lanalytics::Processing::LoadORM::Entity.create(:link_tracking_event) do
              ctx = Lanalytics::Processing::Transformer::LinkTrackingEventElasticSchemaTransformer
              ctx.safe_with_attribute self, :referrer, :string, punit[:referrer]
              ctx.safe_with_attribute self, :referrer_page, :string, punit[:referrer_page]
              ctx.safe_with_attribute self, :course_id, :uuid, punit[:course_id]
              ctx.safe_with_attribute self, :course_id, :uuid, punit[:tracking_course_id]
              ctx.safe_with_attribute self, :user_id, :uuid, punit[:user_id]
              ctx.safe_with_attribute self, :user_id, :uuid, punit[:tracking_user]
              ctx.safe_with_attribute self, :tracking_campaign, :uuid, punit[:tracking_campaign]
              ctx.safe_with_attribute self, :tracking_id, :uuid, punit[:tracking_id]
              ctx.safe_with_attribute self, :tracking_type, :string, punit[:tracking_type]
              ctx.safe_with_attribute self, :tracking_external_link, :string, punit[:tracking_external_link]

              with_attribute :timestamp, :timestamp, punit[:created_at].presence || Time.zone.now
            end

            load_commands << Lanalytics::Processing::LoadORM::CreateCommand.with(entity)
          end
        end

        def self.safe_with_attribute(entity, name, data_type, value)
          return if value.blank?

          entity.with_attribute name, data_type, value
        end
      end
    end
  end
end
# rubocop:enable all
