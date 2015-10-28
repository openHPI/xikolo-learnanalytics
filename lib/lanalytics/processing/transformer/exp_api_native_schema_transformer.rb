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
      with_attribute :user_uuid,       :entity, exp_stmt.user.uuid
      with_attribute :verb,            :string, exp_stmt.verb.type.upcase.to_sym

      verb_entity = Entity.create(:verbs) do
        with_attribute :verb, :string, exp_stmt.verb.type.downcase.to_sym
      end
      with_attribute :verb_id, :int, verb_entity.id

      resource_entity = Entity.create(:resources) do
        with_attribute :resource_uuid, :uuid,   exp_stmt.resource.uuid
        # TODO: Find type
        with_attribute :type,          :string, exp_stmt.resource.uuid
      end
      with_attribute :resource_id, :entity,    resource_entity.id

      with_attribute :in_context,  :json,      exp_stmt.in_context
      with_attribute :with_result, :json,      exp_stmt.with_result
      with_attribute :timestamp,   :timestamp, exp_stmt.timestamp
    end

    load_commands << CreateCommand.with(entity)
  end
end
