require 'digest'
require 'murmurhash3'

module Lanalytics
  module Processing
    module Transformer
      class MoocdbDataTransformer < TransformStep

        def transform(original_event, processing_units, load_commands, pipeline_ctx)

          return if pipeline_ctx.processing_action == Lanalytics::Processing::ProcessingAction::UNDEFINED

          if pipeline_ctx.processing_action == Lanalytics::Processing::ProcessingAction::CREATE
            transform_to_load_commands_for_create(processing_units, load_commands)
          elsif pipeline_ctx.processing_action == Lanalytics::Processing::ProcessingAction::UPDATE
            process_load_commands_for_update
          elsif pipeline_ctx.processing_action == Lanalytics::Processing::ProcessingAction::DESTROY
            process_load_commands_for_destroy
          end
        end

        def transform_to_load_commands_for_create(processing_units, load_commands)
          processing_units.each do | processing_unit |
            entities = self.method("new_#{processing_unit.type.downcase}_entity").call(processing_unit)
            
            if entities.is_a?(Array)
              load_commands.push(*entities.map { |entity| Lanalytics::Processing::LoadORM::MergeEntityCommand.with(entity) })
            else
              load_commands << Lanalytics::Processing::LoadORM::MergeEntityCommand.with(entities)
            end
          end
        end

        def new_user_entity(processing_unit)
          Lanalytics::Processing::LoadORM::Entity.create(:user_pii) do
            # TODO get rid of this
            with_primary_attribute :username, :string, Digest::SHA256.hexdigest(processing_unit.data[:id].to_s)
            with_attribute :global_user_id, :uuid, processing_unit.data[:id]
            with_attribute :gender, :string, nil
            with_attribute :birthday, :date, processing_unit.data[:born_at]
            with_attribute :ip, :string, nil
            with_attribute :country, :string # You can also omit the value parameter
            with_attribute :timezone_offset, :int, nil
          end
        end

        def new_course_entity(processing_unit)
          Lanalytics::Processing::LoadORM::Entity.create(:course) do
            with_primary_attribute :course_id, :uuid, processing_unit.data[:id]
            with_attribute :course_name, :string, processing_unit.data[:title]
            with_attribute :course_start_date, :date, processing_unit.data[:start_date]
            with_attribute :course_end_date, :date, processing_unit.data[:end_date]
          end
        end

        def new_enrollment_entity(processing_unit)
          global_user_id = processing_unit.data[:user_id]
          course_user_id = hash_to_course_user_id(global_user_id)

          global_user_entity = Lanalytics::Processing::LoadORM::Entity.create(:global_user) do
            with_primary_attribute :global_user_id, :uuid, global_user_id
            with_attribute :course_id, :uuid, processing_unit.data[:course_id]
            with_attribute :course_user_id, :uuid, course_user_id
          end

          observing_user_id = hash_to_observing_user_id(global_user_id)
          submitting_user_id = hash_to_submitting_user_id(global_user_id)
          collaborating_user_id = hash_to_collaborating_user_id(global_user_id)
          feedback_user_id = hash_to_feedback_user_id(global_user_id)

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

        def new_item_entity(processing_unit)
          new_item_entity
        end

        # Hashing functions from the gem 'Murmurhash3'
        # More details on https://github.com/funny-falcon/murmurhash3-ruby
        # include MurmurHash32::V32
        # include MurmurHash32::V128
        def hash_to_course_user_id(global_user_id)
          return murmur_hash(global_user_id, 1)
        end

        def hash_to_observing_user_id(global_user_id)
          return murmur_hash(global_user_id, 2)
        end

        def hash_to_submitting_user_id(global_user_id)
          return murmur_hash(global_user_id, 3)
        end

        def hash_to_collaborating_user_id(global_user_id)
          return murmur_hash(global_user_id, 4)
        end

        def hash_to_feedback_user_id(global_user_id)
          return murmur_hash(global_user_id, 5)
        end

        def murmur_hash(global_user_id, seed)
          # return MurmurHash3::V128.fmix(MurmurHash3::V32.str_hash(global_user_id, seed))
          # Returns an unsigned long (32bit)
          return MurmurHash3::V32.str_hash(global_user_id, seed)
        end

      end
    end    
  end
end