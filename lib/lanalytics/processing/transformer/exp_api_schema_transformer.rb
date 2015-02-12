module Lanalytics
  module Processing
    module Transformer
      class ExpApiSchemaTransformer < TransformStep

        def transform(original_event, processing_units, load_commands, pipeline_ctx)

          # Only accepting web events
          processing_units.each do | processing_unit |
            next unless processing_unit.type == :exp_event

            exp_stmt = Lanalytics::Model::ExpApiStatement.new_from_json(processing_unit.data)

            entity = Lanalytics::Processing::LoadORM::Entity.create(:EXP_STATEMENT) do
            
              user_entity = Lanalytics::Processing::LoadORM::Entity.create(:USER) do
                with_primary_attribute :resource_uuid, :uuid, exp_stmt.user.uuid
              end
              with_attribute :user, :entity, user_entity

              with_attribute :verb, :string, exp_stmt.verb.type.upcase.to_sym

              resource_entity = Lanalytics::Processing::LoadORM::Entity.create(exp_stmt.resource.type) do
                with_primary_attribute :resource_uuid, :uuid, exp_stmt.resource.uuid
              end
              with_attribute :resource, :entity, resource_entity


              with_attribute :timestamp, :timestamp, exp_stmt.timestamp

              
              with_result_entity = Lanalytics::Processing::LoadORM::Entity.create(:WITH_RESULT) do
                exp_stmt.with_result.each do | attribute, value |
                  with_attribute attribute.underscore.downcase, :string, value
                end
              end
              with_attribute :with_result, :entity, with_result_entity

              in_context_entity = Lanalytics::Processing::LoadORM::Entity.create(:IN_CONTEXT) do
                exp_stmt.in_context.each do | attribute, value |
                  with_attribute attribute.underscore.downcase, :string, value
                end
              end
              with_attribute :in_context, :entity, in_context_entity
            end

            load_commands << Lanalytics::Processing::LoadORM::CreateCommand.with(entity)

          end

        end

      end
    end
  end
end
