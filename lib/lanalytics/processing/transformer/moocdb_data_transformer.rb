require 'digest'
require 'murmurhash3'

module Lanalytics
  module Processing
    module Transformer
      class MoocdbDataTransformer < TransformStep
        include MoocdbDataSchemaHelper

        def transform(original_event, processing_units, load_commands, pipeline_ctx)
          return if pipeline_ctx.processing_action == Action::UNDEFINED

          action = pipeline_ctx.processing_action.to_s.downcase

          processing_units.each do |processing_unit|
            type = processing_unit.type.to_s.downcase
            transform_method = method("transform_#{type}_punit_to_#{action}_load_commands")

            transform_method.call(processing_unit, load_commands)
          end
        end

        def transform_to_create_load_commands(processing_unit, load_commands)
          transform_method = method("transform_#{processing_unit.type.downcase}_unit")
          entities = transform_method.call(processing_unit)
          load_commands.push(*wrap_in_merge_commands(entities))
        end

        def transform_to_update_load_commands(processing_unit, load_commands)
          transform_method = method("transform_#{processing_unit.type.downcase}_unit")
          entities = transform_method.call(processing_unit)
          load_commands.push(*wrap_in_update_commands(entities))
        end

        def transform_to_destroy_load_commands(processing_unit, load_commands)
          transform_method = method("transform_#{processing_unit.type.downcase}_unit")
          entities = transform_method.call(processing_unit)
          load_commands.push(*wrap_in_destroy_commands(entities))
        end

        # --------------- Alias for Create Events  --------------------
        alias_method :transform_user_punit_to_create_load_commands,       :transform_to_create_load_commands
        alias_method :transform_course_punit_to_create_load_commands,     :transform_to_create_load_commands
        alias_method :transform_item_punit_to_create_load_commands,       :transform_to_create_load_commands
        alias_method :transform_enrollment_punit_to_create_load_commands, :transform_to_create_load_commands
        alias_method :transform_submission_punit_to_create_load_commands, :transform_to_create_load_commands
        alias_method :transform_question_punit_to_create_load_commands,   :transform_to_create_load_commands
        alias_method :transform_answer_punit_to_create_load_commands,     :transform_to_create_load_commands
        alias_method :transform_comment_punit_to_create_load_commands,    :transform_to_create_load_commands

        # --------------- Alias for Update Events  --------------------
        alias_method :transform_user_punit_to_update_load_commands,       :transform_to_update_load_commands
        alias_method :transform_course_punit_to_update_load_commands,     :transform_to_update_load_commands
        alias_method :transform_item_punit_to_update_load_commands,       :transform_to_update_load_commands
        alias_method :transform_question_punit_to_update_load_commands,   :transform_to_update_load_commands
        alias_method :transform_answer_punit_to_update_load_commands,     :transform_to_update_load_commands
        alias_method :transform_comment_punit_to_update_load_commands,    :transform_to_update_load_commands

        # --------------- Alias for Destroy Events  --------------------
        alias_method :transform_course_punit_to_destroy_load_commands,      :transform_to_destroy_load_commands
        alias_method :transform_user_punit_to_destroy_load_commands,        :transform_to_destroy_load_commands
        alias_method :transform_enrollment_punit_to_destroy_load_commands,  :transform_to_destroy_load_commands
        alias_method :transform_item_punit_to_destroy_load_commands,        :transform_to_destroy_load_commands

        def transform_exp_event_punit_to_create_load_commands(processing_unit, load_commands)
          exp_stmt = Lanalytics::Model::ExpApiStatement.new_from_json(processing_unit.data)

          return unless exp_stmt.verb.type.to_s.downcase == 'viewed_page'

          # This is a special situation where the mapping is not that easy and requires some more logic
          load_commands << Lanalytics::Processing::LoadORM::CustomLoadCommand.sql_for(:postgres, %Q{
            UPDATE observed_events
            SET observed_event_duration = 60
            WHERE
              user_id = '#{exp_stmt.user.uuid}'
              AND observed_event_duration IS NULL
              AND (current_timestamp - observed_event_timestamp) > ('60 min'::interval);
          })

          load_commands << Lanalytics::Processing::LoadORM::CustomLoadCommand.sql_for(:postgres, %Q{
            UPDATE observed_events
            SET observed_event_duration = (
              extract(epoch from timestamp with time zone '#{exp_stmt.timestamp}') -
              extract(epoch from observed_event_timestamp)
            ) / 60
            WHERE
              user_id = '#{exp_stmt.user.uuid}'
              AND observed_event_duration IS NULL;
          })

          # At the moment we are only page views on the items page
          match = /^\/courses\/(?<course_code>\w+)\/items\/(?<item_short_uuid>\w+)/.match(exp_stmt.resource.uuid)

          return unless match

          course_code = match[:course_code]
          begin
            item_uuid = UUID(match[:item_short_uuid]).to_s
          rescue Youyouaidi::InvalidUUIDError
            return
          end

          hash = MoocdbDataSchemaHashingHelper.hash_to_url_id(course_code, item_uuid)

          new_exp_event_entity = Lanalytics::Processing::LoadORM::Entity.create(:observed_events) do
            # with_primary_attribute :observed_event_id,          :uuid,      processing_unit[:id]
            with_attribute :user_id, :uuid, exp_stmt.user.uuid
            with_attribute :url_id, :int, hash
            with_attribute :observed_event_timestamp, :timestamp, exp_stmt.timestamp
            with_attribute :observed_event_duration,  :float, nil
            with_attribute :observed_event_ip, :string, exp_stmt.in_context[:user_ip]
            with_attribute :observed_event_os, :int, exp_stmt.in_context[:user_os]
            with_attribute :observed_event_agent, :int, exp_stmt.in_context[:user_agent]
          end

          load_commands << Lanalytics::Processing::LoadORM::CreateCommand.with(new_exp_event_entity)
        end

        def transform_user_unit(processing_unit)
          # TODO: get rid of this digest thing
          born_at = (processing_unit[:born_at] ? Date.parse(processing_unit.data[:born_at]).iso8601 : nil)
          digest = Digest::SHA256.hexdigest(processing_unit.data[:id].to_s)

          Lanalytics::Processing::LoadORM::Entity.create(:user_pii) do
            with_primary_attribute :username, :string, digest
            with_attribute :global_user_id, :uuid, processing_unit.data[:id]
            with_attribute :gender, :string, nil
            with_attribute :birthday, :date, born_at
            with_attribute :ip, :string, nil
            with_attribute :country, :string # You can also omit the value parameter
            with_attribute :timezone_offset, :int, nil
          end
        end

        def transform_course_unit(processing_unit)
          Lanalytics::Processing::LoadORM::Entity.create(:course) do
            with_primary_attribute :course_id, :uuid, processing_unit.data[:id]
            with_attribute :course_name, :string, processing_unit.data[:title]
            with_attribute :course_start_date, :date, processing_unit.data[:start_date]
            with_attribute :course_end_date, :date, processing_unit.data[:end_date]
          end
        end

        def transform_item_unit(processing_unit)
          course = lookup_course(processing_unit.data[:course_id])
          course_code = course[:course_code]

          type_content, type_medium = case processing_unit.data[:content_type]
            when 'video'    then ['lecture', 'video']
            when 'richtext' then ['lecture', 'text']
            when 'quiz'     then ['problem', 'text']
            else                 ['other', 'text']
          end

          resource_type_entity = Lanalytics::Processing::LoadORM::Entity.create(:resource_types) do
            hash = MoocdbDataSchemaHashingHelper.hash_to_resource_type_id(type_content, type_medium)
            with_primary_attribute :resource_type_id, :int, hash
            with_attribute :resource_type_content, :string, type_content
            with_attribute :resource_type_medium, :string, type_medium
          end

          resource_uri = "/courses/#{course_code}/item/#{UUID(processing_unit[:id]).to_short_string}"
          resource_type_id = MoocdbDataSchemaHashingHelper.hash_to_resource_type_id(type_content, type_medium)

          resource_entity = Lanalytics::Processing::LoadORM::Entity.create(:resources) do
            with_primary_attribute :resource_id, :uuid, processing_unit.data[:id]
            with_attribute :resource_name, :string, processing_unit.data[:title]
            with_attribute :resource_uri, :string, resource_uri
            with_attribute :resource_type_id, :int,  resource_type_id
            with_attribute :resource_parent_id, :string, processing_unit[:course_id]
            with_attribute :resource_child_number, :string, nil
            with_attribute :resource_relevant_start_date, :date, processing_unit[:start_date]
            with_attribute :resource_relevant_end_date, :date, processing_unit[:end_date]

            # Change this make a call to the COURSE REST service with Rails Caching mechanism
            with_attribute :resource_relevant_week, :int, processing_unit[:position]

            with_attribute :resource_release_timestamp, :timestamp, processing_unit[:created_at]
          end

          url_id = MoocdbDataSchemaHashingHelper.hash_to_url_id(course_code, processing_unit[:id])

          url_type_entity = Lanalytics::Processing::LoadORM::Entity.create(:urls) do
            with_primary_attribute :url_id, :int, url_id
            with_attribute :url, :string, resource_uri
          end

          resource_url_entity = Lanalytics::Processing::LoadORM::Entity.create(:resource_urls) do
            with_primary_attribute :resources_urls_id, :int, url_id
            with_attribute :resource_id, :uuid, processing_unit.data[:id]
            with_attribute :url_id, :int, url_id
          end

          result = [url_type_entity, resource_url_entity, resource_entity, resource_type_entity]

          if processing_unit.data[:content_type] == 'quiz'
            problem_type_id, problem_type_name = case processing_unit.data[:exercise_type]
              when 'selftest' then [1, 'Homework']
              when 'main'     then [2, 'Final exam']
              when 'bonus'    then [1, 'Homework']
              else                 [0, 'Unknown']
            end

            result << Lanalytics::Processing::LoadORM::Entity.create(:problem_types) do
              with_primary_attribute :problem_type_id, :int, problem_type_id
              with_attribute :problem_type_name, :string, problem_type_name
            end

            deadline = (
              processing_unit[:submission_deadline] ||
              processing_unit[:end_date] ||
              processing_unit[:effective_end_date]
            )
            release = (
              processing_unit[:submission_publishing_date] ||
              processing_unit[:start_date] ||
              processing_unit[:effective_start_date]
            )

            result << Lanalytics::Processing::LoadORM::Entity.create(:problems) do
              with_primary_attribute :problem_id,         :uuid,      processing_unit.data[:id]
              with_attribute :problem_name,               :string,    processing_unit.data[:title]
              with_attribute :problem_parent_id,          :string,    nil
              with_attribute :problem_child_number,       :string,    nil
              with_attribute :problem_type_id,            :int,       problem_type_id
              with_attribute :problem_release_timestamp,  :timestamp, release
              with_attribute :problem_soft_deadline,      :timestamp, deadline
              with_attribute :problem_hard_deadline,      :timestamp, deadline
              with_attribute :problem_max_submission,     :int,       1 # Depends on the problem type
              with_attribute :problem_max_duration,       :int,       nil
              with_attribute :problem_weight,             :int,       nil
              with_attribute :resource_id,                :uuid,      processing_unit.data[:id]
            end
          end

          result
        end

        def transform_enrollment_unit(processing_unit)
          global_user_id = processing_unit.data[:user_id]
          course_user_id = MoocdbDataSchemaHashingHelper.hash_to_course_user_id(global_user_id)

          global_user_entity = Lanalytics::Processing::LoadORM::Entity.create(:global_user) do
            with_primary_attribute :global_user_id, :uuid, global_user_id
            with_attribute :course_id, :uuid, processing_unit.data[:course_id]
            with_attribute :course_user_id, :uuid, course_user_id
          end

          observing_user_id     = MoocdbDataSchemaHashingHelper.hash_to_observing_user_id(global_user_id)
          submitting_user_id    = MoocdbDataSchemaHashingHelper.hash_to_submitting_user_id(global_user_id)
          collaborating_user_id = MoocdbDataSchemaHashingHelper.hash_to_collaborating_user_id(global_user_id)
          feedback_user_id      = MoocdbDataSchemaHashingHelper.hash_to_feedback_user_id(global_user_id)

          course_user_entity = Lanalytics::Processing::LoadORM::Entity.create(:course_user) do
            with_primary_attribute :course_user_id, :int, course_user_id
            with_attribute :course_id, :uuid, processing_unit.data[:course_id]

            with_attribute :observing_user_id, :int, observing_user_id
            with_attribute :submitting_user_id, :int, submitting_user_id
            with_attribute :collaborating_user_id, :int, collaborating_user_id
            with_attribute :feedback_user_id, :int, feedback_user_id

            with_attribute :type, :string, processing_unit.data[:role]
            with_attribute :final_grade, :float, nil # Unknown value at this point
          end

          [global_user_entity, course_user_entity]
        end

        def transform_submission_unit(processing_unit)
          submission_entity = Lanalytics::Processing::LoadORM::Entity.create(:submissions) do
            with_primary_attribute :submission_id,      :uuid,      processing_unit[:id]
            with_attribute :user_id,                    :uuid,      processing_unit[:user_id]
            with_attribute :problem_id,                 :uuid,      processing_unit[:item_id]
            with_attribute :submission_timestamp,       :timestamp, (processing_unit[:quiz_submission_time] || processing_unit[:created_at])
            with_attribute :submission_attempt_number,  :int,       nil
            with_attribute :submission_answer,          :string,    nil
            with_attribute :submission_is_submitted,    :bool,      processing_unit[:submitted]
            with_attribute :submission_ip,              :string,    nil
            with_attribute :submission_os,              :int,       nil
            with_attribute :submission_agent,           :int,       nil
          end

          assessment_entity = Lanalytics::Processing::LoadORM::Entity.create(:assessments) do
            with_primary_attribute :assessment_id,          :uuid,      processing_unit[:id]
            with_attribute :submission_id,                  :uuid,      processing_unit[:id]
            with_attribute :assessment_feedback,            :string,    nil # Unknown at the moment
            with_attribute :assessment_grade,               :float,     processing_unit[:points]
            with_attribute :assessment_grade_with_penalty,  :float,     processing_unit[:points]
            with_attribute :assessment_grader_id,           :uuid,      nil # Unknown at the moment
            with_attribute :assessment_timestamp,           :timestamp, processing_unit[:quiz_submission_time]
          end

          [submission_entity, assessment_entity]
        end

        # ==================== Pinboard Domain Models =====================
        def transform_question_unit(processing_unit)
          new_collaboration(
            processing_unit,
            %Q{
Title: #{processing_unit[:title]}
===============================================
#{processing_unit[:text]}},
            (processing_unit[:course_id] || processing_unit[:learning_room_id])
          )

          # # We cannot link the learning_room in this schema, which is why we are not inlcuding the learning_rooms in the resources table
          # return collaboration_entities if processing_unit[:learning_room_id]

          # course = lookup_course(processing_unit.data[:course_id])

          # type_content, type_medium = ['forum', 'text']

          # resource_type_entity = Lanalytics::Processing::LoadORM::Entity.create(:resource_types) do
          #   with_primary_attribute :resource_type_id, :int, MoocdbDataSchemaHashingHelper.hash_to_resource_type_id(type_content, type_medium)
          #   with_attribute :resource_type_content, :string, type_content
          #   with_attribute :resource_type_medium, :string, type_medium
          # end

          # resource_uri = "/courses/#{course[:course_code]}/item/#{UUID(processing_unit[:id]).to_short_string}"

          # resource_entity = Lanalytics::Processing::LoadORM::Entity.create(:resources) do
          #   with_primary_attribute :resource_id, :uuid, processing_unit.data[:id]
          #   with_attribute :resource_name, :string, "Forum Question #{processing_unit[:id]} for course #{processing_unit[:course_id]}"
          #   with_attribute :resource_uri, :string, resource_uri
          #   with_attribute :resource_type_id, :int, MoocdbDataSchemaHashingHelper.hash_to_resource_type_id(type_content, type_medium)
          #   with_attribute :resource_parent_id, :string, processing_unit[:course_id]
          #   with_attribute :resource_child_number, :string, nil
          #   with_attribute :resource_relevant_start_date, :date, processing_unit[:start_date]
          #   with_attribute :resource_relevant_end_date, :date, processing_unit[:end_date]
          #   with_attribute :resource_relevant_week, :int, processing_unit[:position] # Change this make a call to the COURSE REST service with Rails Caching mechanism
          #   with_attribute :resource_release_timestamp, :timestamp, processing_unit[:created_at]
          # end

          # url_type_entity = Lanalytics::Processing::LoadORM::Entity.create(:urls) do
          #   with_primary_attribute :url_id, :int, MoocdbDataSchemaHashingHelper.hash_to_url_id(course[:course_code], processing_unit[:id])
          #   with_attribute :url, :string, resource_uri
          # end

          # resource_url_entity = Lanalytics::Processing::LoadORM::Entity.create(:resource_urls) do
          #   with_primary_attribute :resources_urls_id, :int, MoocdbDataSchemaHashingHelper.hash_to_url_id(course[:course_code], processing_unit[:id])
          #   with_attribute :resource_id, :uuid, processing_unit.data[:id]
          #   with_attribute :url_id, :int, MoocdbDataSchemaHashingHelper.hash_to_url_id(course[:course_code], processing_unit[:id])
          # end
        end

        def transform_answer_unit(processing_unit)
          new_collaboration(
            processing_unit,
            processing_unit[:text],
            processing_unit[:question_id]
          )
        end

        def transform_comment_unit(processing_unit)
          new_collaboration(
            processing_unit,
            processing_unit[:text],
            processing_unit[:commentable_id]
          )
        end

      end
    end
  end
end
