module Lanalytics
  module Processing
    module Transformer
      class NosqlDataSchemaTransformer < TransformStep
        include Lanalytics::Processing::Transformer::NosqlDataSchemaHelper

        def transform(original_event, processing_units, load_commands, pipeline_ctx)

          if pipeline_ctx.processing_action == Lanalytics::Processing::ProcessingAction::CREATE
            transform_to_load_commands_for_create(processing_units, load_commands)
          elsif pipeline_ctx.processing_action == Lanalytics::Processing::ProcessingAction::UPDATE
            transform_to_load_commands_for_update(processing_units, load_commands)
          elsif pipeline_ctx.processing_action == Lanalytics::Processing::ProcessingAction::DESTROY
            transform_to_load_commands_for_destroy(processing_units, load_commands)
          end

        end

        def transform_to_load_commands_for_create(processing_units, load_commands)
          processing_units.each do | processing_unit |
            
            if processing_unit.type == :exp_event
              load_commands << Lanalytics::Processing::LoadORM::CreateCommand.with(transform_exp_event_unit(processing_unit))
              next
            end

            transform_method = self.method("transform_#{processing_unit.type.downcase}_unit")
            entities = transform_method.call(processing_unit)
            
            if entities.is_a?(Array)
              load_commands.push(*entities.map { |entity| Lanalytics::Processing::LoadORM::MergeEntityCommand.with(entity) })
            else
              load_commands << Lanalytics::Processing::LoadORM::MergeEntityCommand.with(entities)
            end

          end
        end

        def transform_to_load_commands_for_update(processing_units, load_commands)

          processing_units.each do | processing_unit |
            
            transform_method = self.method("transform_#{processing_unit.type.downcase}_unit")
            entities = transform_method.call(processing_unit)
            
            if entities.is_a?(Array)
              load_commands.push(*entities.map { |entity| Lanalytics::Processing::LoadORM::UpdateCommand.with(entity) })
            else
              load_commands << Lanalytics::Processing::LoadORM::UpdateCommand.with(entities)
            end

          end
        end

        def transform_to_load_commands_for_destroy(processing_units, load_commands)
          processing_units.each do | processing_unit |
            
            # An exception for the enrollments
            if processing_unit.type == :enrollment
              relationship = handle_directed_relationship(processing_unit, :UN_ENROLLED, :user_id, :course_id)
              load_commands << Lanalytics::Processing::LoadORM::MergeEntityCommand.with(relationship)
              next
            elsif processing_unit.type == :membership
              relationship = handle_directed_relationship(processing_unit, :UN_JOINED, :user_id, :learning_room_id)
              load_commands << Lanalytics::Processing::LoadORM::MergeEntityCommand.with(relationship)
              next
            elsif processing_unit.type == :subcription
              relationship = handle_directed_relationship(processing_unit, :UN_SUBSCRIBED, :user_id, :question_id)
              load_commands << Lanalytics::Processing::LoadORM::MergeEntityCommand.with(relationship)
              next
            end

            transform_method = self.method("transform_#{processing_unit.type.downcase}_unit")
            entities = transform_method.call(processing_unit)

            if entities.is_a?(Array)
              load_commands.push(*entities.map { |entity| Lanalytics::Processing::LoadORM::DestroyCommand.with(entity) })
            else
              load_commands << Lanalytics::Processing::LoadORM::DestroyCommand.with(entities)
            end

          end
        end

        # new_entity_template
        alias :transform_user_unit :new_entity_template

        def transform_course_unit(processing_unit)
          new_entity_template(processing_unit, [:title, :course_code, :start_date, :end_date])
        end

        def transform_item_unit(processing_unit)
          item_entity = new_entity_template(processing_unit, [:title, :content_type, :start_date, :end_date, :effective_start_date, :effective_end_date, :created_at, :updated_at])

          item_course_rel = Lanalytics::Processing::LoadORM::EntityRelationship.create(:BELONGS_TO) do

            with_from_entity(:ITEM) do
              with_primary_attribute :resource_uuid, :uuid, processing_unit[:id]
            end

            with_to_entity(:COURSE) do
              with_primary_attribute :resource_uuid, :uuid, processing_unit[:course_id]
            end
          end

          return [item_entity, item_course_rel]
        end

        def transform_enrollment_unit(processing_unit)
          handle_directed_relationship(processing_unit, :ENROLLED, :user_id, :course_id)
        end

        def transform_visit_unit(processing_unit)
          handle_directed_relationship(processing_unit, :PROGRESSED, :user_id, :item_id)
        end


        def transform_submission_unit(processing_unit)
          handle_directed_relationship(processing_unit, :SUBMITTED, :user_id, :item_id)
        end

        def transform_learning_room_unit(processing_unit)
          learning_room_entity = new_entity_template(processing_unit)

          learning_room_course_rel = Lanalytics::Processing::LoadORM::EntityRelationship.create(:BELONGS_TO) do

            with_from_entity(:LEARNING_ROOM) do
              with_primary_attribute :resource_uuid, :uuid, processing_unit[:id]
            end

            with_to_entity(:COURSE) do
              with_primary_attribute :resource_uuid, :uuid, processing_unit[:course_id]
            end
          end

          return [learning_room_entity, learning_room_course_rel]
        end
        
        def transform_membership_unit(processing_unit)
          handle_directed_relationship(processing_unit, :JOINED, :user_id, :learning_room_id)
        end

        def transform_subscription_unit(processing_unit)
          handle_directed_relationship(processing_unit, :SUBSCRIBED, :user_id, :question_id)
        end

        def transform_question_unit(processing_unit)

          question_entity = new_entity_template(processing_unit, [:title, :text, :sticky, :deleted, :closed, :discussion_flag, :created_at, :updated_at, :user_tags])

          user_question_rel = Lanalytics::Processing::LoadORM::EntityRelationship.create(:POSTED) do

            with_from_entity(:USER) do
              with_primary_attribute :resource_uuid, :uuid, processing_unit[:user_id]
            end

            with_to_entity(:QUESTION) do
              with_primary_attribute :resource_uuid, :uuid, processing_unit[:id]
            end

            with_attribute :created_at, :datetime, processing_unit[:created_at]
          end


          if processing_unit[:course_id]
            
            question_course_rel = Lanalytics::Processing::LoadORM::EntityRelationship.create(:BELONGS_TO) do

              with_from_entity(:QUESTION) do
                with_primary_attribute :resource_uuid, :uuid, processing_unit[:id]
              end

              with_to_entity(:COURSE) do
                with_primary_attribute :resource_uuid, :uuid, processing_unit[:course_id]
              end
            end

            return [question_entity, user_question_rel, question_course_rel]

          elsif processing_unit[:learning_room_id]

            question_learning_room_rel = Lanalytics::Processing::LoadORM::EntityRelationship.create(:BELONGS_TO) do

              with_from_entity(:QUESTION) do
                with_primary_attribute :resource_uuid, :uuid, processing_unit[:id]
              end

              with_to_entity(:LEARNING_ROOM) do
                with_primary_attribute :resource_uuid, :uuid, processing_unit[:learning_room_id]
              end
            end

            return [question_entity, user_question_rel, question_learning_room_rel]
          
          else
            Rails.logger.warn 'No connection could be found to :COURSE or :LEARNING_ROOM'
          end

        end

        def transform_answer_unit(processing_unit)

          answer_entity = new_entity_template(processing_unit, [:text, :created_at, :updated_at])

          user_answer_rel = Lanalytics::Processing::LoadORM::EntityRelationship.create(:POSTED_ANSWER) do
            with_from_entity(:USER) { with_primary_attribute :resource_uuid, :uuid, processing_unit[:user_id] }
            with_to_entity(:ANSWER) { with_primary_attribute :resource_uuid, :uuid, processing_unit[:id] }
            with_attribute :created_at, :datetime, processing_unit[:created_at]
          end

          answer_question_rel = Lanalytics::Processing::LoadORM::EntityRelationship.create(:BELONGS_TO) do

            with_from_entity(:ANSWER) do
              with_primary_attribute :resource_uuid, :uuid, processing_unit[:id]
            end

            with_to_entity(:QUESTION) do
              with_primary_attribute :resource_uuid, :uuid, processing_unit[:question_id]
            end

            with_attribute :created_at, :datetime, processing_unit[:created_at]
          end

          return [answer_entity, user_answer_rel, answer_question_rel]

        end

        def transform_comment_unit(processing_unit)

          Lanalytics::Processing::LoadORM::EntityRelationship.create(:COMMENTED) do

            with_primary_attribute :relationship_uuid, :uuid, processing_unit[:id]

            with_from_entity(:USER) do
              with_primary_attribute :resource_uuid, :uuid, processing_unit[:user_id]
            end

            with_to_entity(processing_unit[:commentable_type].to_sym.upcase) do
              with_primary_attribute :resource_uuid, :uuid, processing_unit[:commentable_id]
            end

            processing_unit.data.except(:user_id, :id, :commentable_id, :commentable_type).each do |property, value|
              with_attribute property.downcase.to_sym, :string, value
            end
          end

        end

        def transform_ticket_unit(processing_unit)
          
          helpdesk_ticket_entity = new_entity_template(processing_unit, [:url, :language, :mail, :report, :title, :data, :created_at])

          result = [helpdesk_ticket_entity]

          if processing_unit[:user_id]
            result << Lanalytics::Processing::LoadORM::EntityRelationship.create(:SUBMITTED_FEEDBACK_FROM) do

              with_from_entity(:USER) do
                with_primary_attribute :resource_uuid, :uuid, processing_unit[:user_id]
              end

              with_to_entity(:TICKET) do
                with_primary_attribute :resource_uuid, :uuid, processing_unit[:id]
              end

              with_attribute :created_at, :timestamp, processing_unit[:created_at]
            end 
          end

          if processing_unit[:course_id]
            result << Lanalytics::Processing::LoadORM::EntityRelationship.create(:SUBMITTED_FEEDBACK_FOR) do

              with_from_entity(:TICKET) do
                with_primary_attribute :resource_uuid, :uuid, processing_unit[:id]
              end

              with_to_entity(:COURSE) do
                with_primary_attribute :resource_uuid, :uuid, processing_unit[:course_id]
              end

              with_attribute :created_at, :timestamp, processing_unit[:created_at]
            end 
          end

          return result

        end


        def transform_exp_event_unit(exp_event_unit)

          exp_stmt = Lanalytics::Model::ExpApiStatement.new_from_json(exp_event_unit.data)
          # TODO:: shift ExpAPIStatement to LoadORM as special class
          Lanalytics::Processing::LoadORM::EntityRelationship.create(exp_stmt.verb.type.upcase.to_sym) do
            
            with_from_entity(:USER) do
              with_primary_attribute :resource_uuid, :uuid, exp_stmt.user.uuid
            end

            with_to_entity(exp_stmt.resource.type) do
              with_primary_attribute :resource_uuid, :uuid, exp_stmt.resource.uuid
            end

            with_attribute :timestamp, :datetime, exp_stmt.timestamp
            
            exp_stmt.with_result.each do | attribute, value |
              with_attribute "with_result_#{attribute.underscore.downcase}", :string, value
            end

            exp_stmt.in_context.each do | attribute, value |
              with_attribute "in_context_#{attribute.underscore.downcase}", :string, value
            end
          end

        end
      end
    end    
  end
end