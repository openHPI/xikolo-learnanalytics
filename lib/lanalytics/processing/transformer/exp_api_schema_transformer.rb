module Lanalytics
  module Processing
    module Transformer
      class ExpApiSchemaTransformer < TransformStep
        def transform(_original_event, processing_units, load_commands, pipeline_ctx)
          processing_action = pipeline_ctx.processing_action.to_s.downcase

          processing_units.each do | processing_unit |
            processing_unit_type = processing_unit.type.to_s.downcase
            transform_method = method("transform_#{processing_unit_type}_punit_to_#{processing_action}")
            transform_method.call(processing_unit, load_commands)
          end
        end

        def transform_exp_event_punit_to_create(processing_unit, load_commands)
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

        def transform_question_punit_to_create(processing_unit, _load_commands)
          transform_punit_to_create _load_commands,
                                    USER: { resource_uuid: processing_unit[:user_id] },
                                    verb: :ASKED_QUESTION,
                                    resource: {
                                      resource_uuid: processing_unit[:id],
                                      title: processing_unit[:title],
                                      text: processing_unit[:text]
                                    },
                                    timestamp: processing_unit[:created_at],
                                    in_context: {
                                      course_id: processing_unit[:course_id],
                                      video_id: processing_unit[:video_id],
                                      video_timestamp: processing_unit[:video_timestamp],
                                      learning_room_id: processing_unit[:learning_room_id],
                                      implicit_tags: processing_unit[:implicit_tags],
                                      user_tags: processing_unit[:user_tags],
                                      technical: processing_unit[:technical]
                                    }
        end

        def transform_answer_punit_to_create(processing_unit, _load_commands)
          transform_punit_to_create _load_commands,
                                    USER: { resource_uuid: processing_unit[:user_id] },
                                    verb: :ANSWERED_QUESTION,
                                    resource: {
                                      resource_uuid: processing_unit[:id],
                                      text: processing_unit[:text]
                                    },
                                    timestamp: processing_unit[:created_at],
                                    in_context: {
                                      question_id: processing_unit[:question_id],
                                      course_id: processing_unit[:course_id],
                                      technical: processing_unit[:technical]
                                    }
        end

        def transform_comment_punit_to_create(processing_unit, _load_commands)
          transform_punit_to_create _load_commands,
                                    USER: { resource_uuid: processing_unit[:user_id] },
                                    verb: :COMMENTED,
                                    resource: {
                                      resource_uuid: processing_unit[:id],
                                      text: processing_unit[:text]
                                    },
                                    timestamp: processing_unit[:created_at],
                                    in_context: {
                                      commentable_id: processing_unit[:commentable_id],
                                      commentable_type: processing_unit[:commentable_type],
                                      course_id: processing_unit[:course_id],
                                      technical: processing_unit[:technical]
                                    }
        end

        def transform_punit_to_create(load_commands, attrs)
          entity = Lanalytics::Processing::LoadORM::Entity.create(:EXP_STATEMENT) do
            user_entity = Lanalytics::Processing::LoadORM::Entity.create(:USER) do
              with_primary_attribute :resource_uuid, :uuid, attrs[:USER][:resource_uuid]
            end
            with_attribute :user, :entity, user_entity

            with_attribute :verb, :string, attrs[:verb]

            resource_entity = Lanalytics::Processing::LoadORM::Entity.create(:resource) do
              with_primary_attribute :resource_uuid, :uuid, attrs[:resource][:resource_uuid]
              attrs[:resource].except(:resource_uuid).each do | attribute, value |
                with_attribute attribute.to_s.downcase, :string, value
              end
            end
            with_attribute :resource, :entity, resource_entity

            with_attribute :timestamp, :timestamp, attrs[:resource][:timestamp]

            in_context_entity = Lanalytics::Processing::LoadORM::Entity.create(:IN_CONTEXT) do
              attrs[:in_context].each do | attribute, value |
                with_attribute attribute.to_s.downcase, :string, value
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
