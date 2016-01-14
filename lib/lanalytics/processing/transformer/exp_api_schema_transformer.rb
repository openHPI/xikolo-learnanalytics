module Lanalytics
  module Processing
    module Transformer
      class ExpApiSchemaTransformer < TransformStep

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

          entity = Lanalytics::Processing::LoadORM::Entity.create(:EXP_STATEMENT) do
            user_entity = Lanalytics::Processing::LoadORM::Entity.create(:user) do
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
              # TODO: Refactor the underscore.downcase conversion to support
              # nested json in the future
              exp_stmt.with_result.each do |attribute, value|
                with_attribute attribute.underscore.downcase, :string, value
              end
            end
            with_attribute :with_result, :entity, with_result_entity

            in_context_entity = Lanalytics::Processing::LoadORM::Entity.create(:IN_CONTEXT) do
              # TODO: Refactor the underscore.downcase conversion to support
              # nested json in the future
              exp_stmt.in_context.each do |attribute, value|
                with_attribute attribute.underscore.downcase, :string, value
              end
            end
            with_attribute :in_context, :entity, in_context_entity
          end

          load_commands << Lanalytics::Processing::LoadORM::CreateCommand.with(entity)
        end

        #
        # Method that should be called by all individual methods below
        # Transforms everything to super-fancy object-oriented attributes / entities
        #
        def transform_punit_to_create(load_commands, attrs)
          entity = Lanalytics::Processing::LoadORM::Entity.create(:EXP_STATEMENT) do
            user_entity = Lanalytics::Processing::LoadORM::Entity.create(:user) do
              with_primary_attribute :resource_uuid, :uuid, attrs[:user][:resource_uuid]
            end
            with_attribute :user, :entity, user_entity

            with_attribute :verb, :string, attrs[:verb]

            resource_entity = Lanalytics::Processing::LoadORM::Entity.create(:resource) do
              unless attrs[:resource].nil?
                with_primary_attribute :resource_uuid, :uuid, attrs[:resource][:resource_uuid]
                attrs[:resource].except(:resource_uuid).each do |attribute, value|
                  with_attribute attribute.to_s.downcase, :string, value
                end
              end
            end
            with_attribute :resource, :entity, resource_entity

            with_attribute :timestamp, :timestamp, attrs[:timestamp]

            in_context_entity = Lanalytics::Processing::LoadORM::Entity.create(:IN_CONTEXT) do
              attrs[:in_context].each do |attribute, value|
                if [
                  :points_achieved,
                  :points_maximal,
                  :points_percentage,
                  :quantile
                ].include? attribute
                  with_attribute attribute.to_s.downcase, :float, value
                elsif [
                  :received_confirmation_of_participation,
                  :received_record_of_achievement,
                  :received_certificate
                ].include? attribute
                  with_attribute attribute.to_s.downcase, :bool, (value.nil? ? false : value)
                else
                  with_attribute attribute.to_s.downcase, :string, value
                end
              end
            end
            with_attribute :in_context, :entity, in_context_entity
          end

          load_commands << Lanalytics::Processing::LoadORM::CreateCommand.with(entity)
        end

        def transform_question_punit_to_create(processing_unit, load_commands)
          transform_punit_to_create load_commands,
                                    user: {
                                      resource_uuid: processing_unit[:user_id]
                                    },
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

        def transform_answer_punit_to_create(processing_unit, load_commands)
          transform_punit_to_create load_commands,
                                    user: {
                                      resource_uuid: processing_unit[:user_id]
                                    },
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

        def transform_comment_punit_to_create(processing_unit, load_commands)
          transform_punit_to_create load_commands,
                                    user: {
                                      resource_uuid: processing_unit[:user_id]
                                    },
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

        def transform_visit_punit_to_create(processing_unit, load_commands)
          transform_punit_to_create load_commands,
                                    user: {
                                      resource_uuid: processing_unit[:user_id]
                                    },
                                    verb: :VISITED,
                                    resource: {
                                      resource_uuid: processing_unit[:item_id],
                                      content_type: processing_unit[:content_type]
                                    },
                                    timestamp: processing_unit[:created_at],
                                    in_context: {
                                      course_id: processing_unit[:course_id]
                                    }
        end

        def transform_watch_punit_to_create(processing_unit, load_commands)
          transform_punit_to_create load_commands,
                                    user: {
                                      resource_uuid: processing_unit[:user_id]
                                    },
                                    verb: :WATCHED_QUESTION,
                                    resource: {
                                      resource_uuid: processing_unit[:question_id]
                                    },
                                    timestamp: processing_unit[:updated_at],
                                    in_context: {
                                      course_id: processing_unit[:course_id]
                                    }
        end

        def transform_enrollment_completed_punit_to_create(processing_unit, load_commands)
          transform_punit_to_create load_commands,
                                    user: {
                                      resource_uuid: processing_unit[:user_id]
                                    },
                                    verb: :COMPLETED_COURSE,
                                    resource: {
                                      resource_uuid: processing_unit[:course_id]
                                    },
                                    timestamp: processing_unit[:updated_at],
                                    in_context: {
                                      course_id: processing_unit[:course_id],
                                      points_achieved: processing_unit[:points][:achieved],
                                      points_maximal: processing_unit[:points][:maximal],
                                      points_percentage: processing_unit[:points][:percentage],
                                      received_confirmation_of_participation: processing_unit[:certificates][:confirmation_of_participation],
                                      received_record_of_achievement: processing_unit[:certificates][:record_of_achievement],
                                      received_certificate: processing_unit[:certificates][:certificate],
                                      quantile: processing_unit[:quantile]
                                    }
        end

        def transform_answer_accepted_punit_to_create(processing_unit, load_commands)
          transform_punit_to_create load_commands,
                                    user: {
                                        resource_uuid: processing_unit[:user_id]
                                    },
                                    verb: :ANSWER_ACCEPTED,
                                    resource: {
                                        resource_uuid: processing_unit[:id]
                                    },
                                    timestamp: processing_unit[:timestamp],
                                    in_context: {
                                        course_id: processing_unit[:course_id],
                                        question_id: processing_unit[:question_id]
                                    }
        end

        def transform_enrollment_punit_to_create(processing_unit, load_commands)
          save_enrollment(processing_unit, load_commands)
        end

        def transform_enrollment_punit_to_update(processing_unit, load_commands)
          save_enrollment(processing_unit, load_commands)
        end

        def save_enrollment(processing_unit, load_commands)
          verb = processing_unit[:deleted] ? :UN_ENROLLED : :ENROLLED
          transform_punit_to_create load_commands,
                                    user: {
                                      resource_uuid: processing_unit[:user_id]
                                    },
                                    verb: verb,
                                    resource: {
                                      resource_uuid: processing_unit[:course_id]
                                    },
                                    timestamp: processing_unit[:updated_at],
                                    in_context: {
                                      course_id: processing_unit[:course_id]
                                    }
        end

        def transform_user_punit_to_create(processing_unit, load_commands)
          transform_punit_to_create load_commands,
                                    user: {
                                      resource_uuid: processing_unit[:id]
                                    },
                                    verb: :confirmed,
                                    timestamp: processing_unit[:updated_at],
                                    in_context: {
                                      affiliated: processing_unit[:affiliated],
                                      admin: processing_unit[:admin],
                                      policy_accepted: processing_unit[:policy_accepted],
                                      preferred_language: processing_unit[:preferred_language]
                                    }
        end

      end
    end
  end
end
