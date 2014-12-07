# require 'activesupport'

module Lanalytics
  module Processing
    module Transformer
      module MoocdbDataSchemaHelper

        def wrap_in_merge_commands(entities)

          entities = yield if block_given?

          if entities.is_a?(Array)
            return entities.map { |entity| Lanalytics::Processing::LoadORM::MergeEntityCommand.with(entity) }
          else
            return [Lanalytics::Processing::LoadORM::MergeEntityCommand.with(entities)]
          end
        end

        def wrap_in_update_commands(entities)

          entities = yield if block_given?

          if entities.is_a?(Array)
            return entities.map { |entity| Lanalytics::Processing::LoadORM::UpdateCommand.with(entity) }
          else
            return [Lanalytics::Processing::LoadORM::UpdateCommand.with(entities)]
          end
        end

        def new_collaboration(processing_unit, collaboration_content, collaboration_parent_id)
          collaboration_type_id, collaboration_type_name = collaboration_type(processing_unit)

          collaboration_type_entity = new_collaboration_type_entity(collaboration_type_id, collaboration_type_name)

          collaboration_entity = new_collaboration_entity(processing_unit, collaboration_type_id, collaboration_content, collaboration_parent_id)
          
          return [collaboration_type_entity, collaboration_entity]
        end

        def new_collaboration_entity(processing_unit, collaboration_type_id, collaboration_content, collaboration_parent_id)

          return Lanalytics::Processing::LoadORM::Entity.create(:collaborations) do
            with_primary_attribute :collaboration_id, :uuid, processing_unit[:id]
            with_attribute :user_id, :uuid, processing_unit[:user_id]
            with_attribute :collaboration_type_id, :int, collaboration_type_id
            with_attribute :collaboration_timestamp, :timestamp, processing_unit[:created_at]
            with_attribute :collaboration_content, :string, collaboration_content
            with_attribute :collaboration_parent_id, :uuid, collaboration_parent_id
            with_attribute :collaboration_child_number, :int, nil
            with_attribute :collaborations_ip, :string, nil
            with_attribute :collaborations_os, :int, nil
            with_attribute :collaborations_agent, :int, nil
            with_attribute :resource_id, :uuid, processing_unit[:id]
            with_attribute :collaboration_thread_id, :uuid, collaboration_parent_id
          end
        end

        def new_collaboration_type_entity(collboration_type_id, collaboration_type_name)
          return Lanalytics::Processing::LoadORM::Entity.create(:collaboration_types) do
            with_primary_attribute :collaboration_type_id, :int, collboration_type_id
            with_attribute :collaboration_type_name, :string, collaboration_type_name
          end
        end

        def collaboration_type(processing_unit)
          return case processing_unit.type
            when :question  then [1, 'forum_question']
            when :answer    then [2, 'forum_answer']
            when :comment   then [3, 'forum_comment']
          end
        end

        def lookup_course(course_id)

          @course_cache = ActiveSupport::Cache::MemoryStore.new

          # If course is not there, then nil is returned
          if course = @course_cache.read(course_id)
            return course
          end

          service_base_urls = YAML.load_file("#{Rails.root}/config/services.yml")
          service_base_urls = (service_base_urls[Rails.env] || service_base_urls)['services']
          course_service_base_url = service_base_urls['course']
          json_url = "#{course_service_base_url}/courses/#{course_id}.json"
          course_data = nil
          begin
            course_service_rest_response = RestClient.get(json_url)
            course_data = MultiJson.load(course_service_rest_response, symbolize_keys: true)
          rescue Exception => any_error
            Rails.logger.error "Following error happened when trying to retrieve additional information for the transforming of items in the MoocdbDataTransformer: #{any_error.message}"
            throw any_error
          end

          raise Error.new "No course data could be retrieved for uuid #{course_id}" unless course_data
          
          @course_cache.write(course_id, course_data)
          return course_data

        end

      end
    end
  end
end