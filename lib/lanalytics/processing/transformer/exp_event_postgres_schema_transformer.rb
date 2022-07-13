# frozen_string_literal: true

Transformer     = Lanalytics::Processing::Transformer
CreateCommand   = Lanalytics::Processing::LoadORM::CreateCommand
Entity          = Lanalytics::Processing::LoadORM::Entity
ExpApiStatement = Lanalytics::Model::ExpApiStatement

# rubocop:disable Metrics/ClassLength, Layout/LineLength
class Transformer::ExpEventPostgresSchemaTransformer < Transformer::TransformStep
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

  # Transform events coming from Javascript through the web service.
  def transform_exp_event_punit_to_create(processing_unit, load_commands)
    exp_stmt = ExpApiStatement.new_from_json(processing_unit.data)

    entity = Entity.create(:events) do
      with_attribute :user_uuid, :string, exp_stmt.user.uuid

      verb = Verb.find_or_create_by(verb: exp_stmt.verb.type.downcase)
      with_attribute :verb_id, :int, verb.id

      unless exp_stmt.resource.nil?
        resource = Resource.find_or_create_by(
          uuid: exp_stmt.resource.uuid.to_s,
          resource_type: exp_stmt.resource.type.downcase.to_s
        )
        with_attribute :resource_id, :int, resource.id
      end

      in_context  = hash_keys_to_underscore(exp_stmt.in_context.presence)
      with_result = hash_keys_to_underscore(exp_stmt.with_result.presence)

      with_attribute :in_context,  :json,      in_context
      with_attribute :with_result, :json,      with_result
      with_attribute :created_at,  :timestamp, exp_stmt.timestamp
      with_attribute :updated_at,  :timestamp, exp_stmt.timestamp
    end

    load_commands << CreateCommand.with(entity)
  end

  # General method that transforms an event with a specific entity
  # (usually coming from any service) to a load command
  def transform_punit_to_create(load_commands, attrs)
    entity = Entity.create(:events) do
      with_attribute :user_uuid, :string, attrs[:user_uuid]

      verb = Verb.find_or_create_by(verb: attrs[:verb])
      with_attribute :verb_id, :int, verb.id

      unless attrs[:resource].nil?
        resource = Resource.find_or_create_by(
          uuid: attrs[:resource][:uuid].to_s,
          resource_type: attrs[:resource][:type].to_s
        )
        with_attribute :resource_id, :int, resource.id
      end

      with_attribute :in_context,  :json,      attrs[:in_context]
      with_attribute :with_result, :json,      attrs[:with_result]
      with_attribute :created_at,  :timestamp, attrs[:timestamp]
      with_attribute :updated_at,  :timestamp, attrs[:timestamp]
    end

    load_commands << Lanalytics::Processing::LoadORM::CreateCommand.with(entity)
  end

  def transform_question_punit_to_create(processing_unit, load_commands)
    transform_punit_to_create load_commands,
      user_uuid: processing_unit[:user_id],
      verb: :asked_question,
      resource: {
        uuid: processing_unit[:id],
        type: :question,
      },
      timestamp: processing_unit[:created_at],
      in_context: {
        text: processing_unit[:text],
        course_id: processing_unit[:course_id],
        video_id: processing_unit[:video_id],
        video_timestamp: processing_unit[:video_timestamp],
        learning_room_id: processing_unit[:learning_room_id],
        implicit_tags: processing_unit[:implicit_tags],
        user_tags: processing_unit[:user_tags],
        technical: processing_unit[:technical],
      }
  end

  def transform_answer_punit_to_create(processing_unit, load_commands)
    transform_punit_to_create load_commands,
      user_uuid: processing_unit[:user_id],
      verb: :answered_question,
      resource: {
        uuid: processing_unit[:id],
        type: :answer,
      },
      timestamp: processing_unit[:created_at],
      in_context: {
        text: processing_unit[:text],
        question_id: processing_unit[:question_id],
        course_id: processing_unit[:course_id],
        technical: processing_unit[:technical],
      }
  end

  def transform_comment_punit_to_create(processing_unit, load_commands)
    transform_punit_to_create load_commands,
      user_uuid: processing_unit[:user_id],
      verb: :commented,
      resource: {
        uuid: processing_unit[:id],
        type: :comment,
      },
      timestamp: processing_unit[:created_at],
      in_context: {
        text: processing_unit[:text],
        commentable_id: processing_unit[:commentable_id],
        commentable_type: processing_unit[:commentable_type],
        course_id: processing_unit[:course_id],
        technical: processing_unit[:technical],
      }
  end

  def transform_visit_punit_to_create(processing_unit, load_commands)
    transform_punit_to_create load_commands,
      user_uuid: processing_unit[:user_id],
      verb: :visited,
      resource: {
        uuid: processing_unit[:item_id],
        type: processing_unit[:content_type],
      },
      timestamp: processing_unit[:created_at],
      in_context: {
        course_id: processing_unit[:course_id],
      }
  end

  def transform_watch_punit_to_create(processing_unit, load_commands)
    transform_punit_to_create load_commands,
      user_uuid: processing_unit[:user_id],
      verb: :watched_question,
      resource: {
        uuid: processing_unit[:question_id],
        type: :question,
      },
      timestamp: processing_unit[:updated_at],
      in_context: {
        course_id: processing_unit[:course_id],
      }
  end

  def transform_enrollment_completed_punit_to_create(processing_unit, load_commands)
    transform_punit_to_create load_commands,
      user_uuid: processing_unit[:user_id],
      verb: :completed_course,
      resource: {
        uuid: processing_unit[:course_id],
        type: :course,
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
        quantile: processing_unit[:quantile],
      }
  end

  def transform_answer_accepted_punit_to_create(processing_unit, load_commands)
    transform_punit_to_create load_commands,
      user_uuid: processing_unit[:user_id],
      verb: :answer_accepted,
      resource: {
        uuid: processing_unit[:id],
        type: :answer,
      },
      timestamp: processing_unit[:created_at],
      in_context: {
        course_id: processing_unit[:course_id],
        question_id: processing_unit[:question_id],
      }
  end

  def transform_enrollment_punit_to_create(processing_unit, load_commands)
    save_enrollment(processing_unit, load_commands)
  end

  def transform_enrollment_punit_to_update(processing_unit, load_commands)
    save_enrollment(processing_unit, load_commands)
  end

  def save_enrollment(processing_unit, load_commands)
    verb = processing_unit[:deleted] ? :un_enrolled : :enrolled
    transform_punit_to_create load_commands,
      user_uuid: processing_unit[:user_id],
      verb: verb,
      resource: {
        uuid: processing_unit[:course_id],
        type: :course,
      },
      timestamp: processing_unit[:updated_at],
      in_context: {
        course_id: processing_unit[:course_id],
      }
  end

  def transform_user_punit_to_create(processing_unit, load_commands)
    transform_punit_to_create load_commands,
      user_uuid: processing_unit[:id],
      verb: :confirmed,
      timestamp: processing_unit[:updated_at],
      in_context: {
        affiliated: processing_unit[:affiliated],
        admin: processing_unit[:admin],
        policy_accepted: processing_unit[:policy_accepted],
        preferred_language: processing_unit[:preferred_language],
      }
  end

  def transform_submission_punit_to_create(processing_unit, load_commands)
    transform_punit_to_create load_commands,
      user_uuid: processing_unit[:user_id],
      verb: :submitted_quiz,
      resource: {
        uuid: processing_unit[:quiz_id],
        type: :quiz,
      },
      timestamp: processing_unit[:quiz_submission_time] || DateTime.now.to_s,
      in_context: {
        course_id: processing_unit[:course_id],
        item_id: processing_unit[:item_id],
        quiz_access_time: processing_unit[:quiz_access_time],
        quiz_submission_time: processing_unit[:quiz_submission_time],
        quiz_version_at: processing_unit[:quiz_version_at],
        quiz_submission_deadline: processing_unit[:quiz_submission_deadline],
        quiz_type: processing_unit[:quiz_type],
        attempt: processing_unit[:attempt],
        points: processing_unit[:points],
        max_points: processing_unit[:max_points],
        estimated_time_effort: processing_unit[:estimated_time_effort],
      }
  end
end
# rubocop:enable all
