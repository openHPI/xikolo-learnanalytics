Transformer   = Lanalytics::Processing::Transformer
CreateCommand = Lanalytics::Processing::LoadORM::CreateCommand
Entity        = Lanalytics::Processing::LoadORM::Entity

class Transformer::ExpApiNativeSchemaTransformer < Transformer::TransformStep
  def transform(_original_event, processing_units, load_commands, pipeline_ctx)
    processing_action = pipeline_ctx.processing_action.to_s.downcase

    processing_units.each do |processing_unit|
      processing_unit_type = processing_unit.type.to_s.downcase
      transform_method = "transform_#{processing_unit_type}_punit_to_#{processing_action}"
      if respond_to? transform_method.to_sym
        method(transform_method).call(processing_unit, load_commands)
      else
        Rails.logger.error "#{transform_method} does not exist"
      end
    end
  end

  def transform_exp_event_punit_to_create(processing_unit, load_commands)
    exp_stmt = Lanalytics::Model::ExpApiStatement.new_from_json(processing_unit.data)

    entity = Entity.create(:events) do
      with_attribute :user_uuid, :entity, exp_stmt.user.uuid

      verb =
      with_attribute :verb, :string, exp_stmt.verb.type.upcase.to_sym


      with_attribute :resource_uuid, :uuid, exp_stmt.resource.uuid

      with_attribute :resource, :entity, resource_entity

      with_attribute :timestamp, :timestamp, exp_stmt.timestamp

      with_result_entity = Entity.create(:WITH_RESULT) do
        exp_stmt.with_result.each do |attribute, value|
          with_attribute attribute.underscore.downcase, :string, value
        end
      end
      with_attribute :with_result, :entity, with_result_entity

      in_context_entity = Entity.create(:IN_CONTEXT) do
        exp_stmt.in_context.each do |attribute, value|
          with_attribute attribute.underscore.downcase, :string, value
        end
      end
      with_attribute :in_context, :entity, in_context_entity
    end

    load_commands << CreateCommand.with(entity)
  end
end
