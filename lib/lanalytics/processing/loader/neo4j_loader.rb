module Lanalytics
  module Processing
    module Loader
      # TODO::Check naming of some variables in this class

      class Neo4jLoader < LoadStep
        
        def load(processing_unit, load_commands, pipeline_ctx)

          load_commands.each do | load_command |
            begin
              self.method("do_#{load_command.class.name.demodulize.underscore}_for_#{load_command.entity.class.name.demodulize.underscore}").call(load_command)
            rescue Exception => e
              Rails.logger.error(%Q{Happened in pipeline '#{pipeline_ctx.pipeline.full_name}' for processing_unit: #{e.message}
#{processing_unit.inspect}
              })  
            end
          end

        end

        def do_merge_entity_command_for_entity(merge_entity_command)
          entity = merge_entity_command.entity

          resource_type = entity.entity_key
          resource_properties = Hash[entity.all_non_nil_attributes.map { | attr | [attr.name, attr.value] }]

          begin
            neo4j_query = Neo4j::Session.query
              .merge(r: {resource_type => {entity.primary_attribute.name => entity.primary_attribute.value }})
              .on_create_set(r: resource_properties)
              .on_match_set(r: resource_properties)

            neo4j_query.exec
          rescue Exception => e
            Rails.logger.error(%Q{
Following error occurred when executing a Cypher query on Neo4j: #{e.message}
#{neo4j_query.to_cypher}
            })
            throw e
          end
        end

        def do_update_command_for_entity(update_command)
            entity = update_command.entity
            resource_type = entity.entity_key
            resource_properties = Hash[entity.all_non_nil_attributes.map { | attr | [attr.name, attr.value] }]

            Neo4j::Session.query
            .match(r: {resource_type => {entity.primary_attribute.name => entity.primary_attribute.value }})
            .set_props(r: resource_properties)
            .exec
            # .on_create_set(r: resource_properties)
            # .on_match_set(r: resource_properties)
        end

        def do_merge_entity_command_for_entity_relationship(merge_entity_command)

          entity_rel = merge_entity_command.entity

          from_entity_key = entity_rel.from_entity.entity_key
          from_entity_pattribute = entity_rel.from_entity.primary_attribute
          to_entity_key = entity_rel.to_entity.entity_key
          to_entity_pattribute = entity_rel.to_entity.primary_attribute

          Neo4j::Session.query
            .merge(r1: {from_entity_key.to_sym => {from_entity_pattribute.name.to_sym => from_entity_pattribute.value.to_s }}).break
            .merge(r2: {to_entity_key.to_sym => {to_entity_pattribute.name.to_sym => to_entity_pattribute.value.to_s }}).break
            .merge("(r1)-[:#{entity_rel.relationship_key} #{Neo4j::Core::Query.new.merge(Hash[entity_rel.all_non_nil_attributes.map { |attr| [attr.name.to_s, attr.value.to_s] }]).to_cypher[8..-2]}]->(r2)")
            .exec
        end

        def do_destroy_command_for_entity_relationship(destroy_command)

          entity_rel = destroy_command.entity
          entity_rel_type = entity_rel.relationship_key
          entity_rel_primary_attribue_name = entity_rel.primary_attribute.name
          entity_rel_primary_attribue_value = entity_rel.primary_attribute.value.to_s
          Neo4j::Session.query
            .match("()-[r:#{entity_rel_type} {#{entity_rel_primary_attribue_name}:\"#{entity_rel_primary_attribue_value}\"}]->()")
            .delete(:r)
            .exec
        end

        def do_destroy_command_for_entity(destroy_command)
          entity = destroy_command.entity
          enitity_type = entity.entity_key
          Neo4j::Session.query
            .match(e: {enitity_type => {entity.primary_attribute.name => entity.primary_attribute.value }})
            .delete(:e)
            .exec
        end

        # def load(processing_unit, load_commands, pipeline_ctx)
          
        #   if processed_resources.nil? or processed_resources.empty?
        #     puts "'processed_resources' cannot be nil or empty"
        #     return
        #   end

        #   processed_resources.each do | processed_resource |

        #     if opts[:processing_action] == Lanalytics::Processing::ProcessingAction::CREATE or
        #       opts[:processing_action] == Lanalytics::Processing::ProcessingAction::UPDATE
        #       case processed_resource
        #       when Lanalytics::Model::StmtResource
        #         self.merge_resource(original_resource_as_hash, processed_resource)
        #       when Lanalytics::Model::ResourceRelationship
        #         self.merge_relationship(original_resource_as_hash, processed_resource)
        #       when Lanalytics::Model::ExpApiStatement
        #         self.create_experience_statement(original_resource_as_hash, processed_resource)
        #       else
        #         puts "'processed_resource' (#{processed_resource.class.name}) could not be mapped to an operation"
        #       end
        #     elsif opts[:processing_action] == Lanalytics::Processing::ProcessingAction::DESTROY
        #       case processed_resource
        #       when Lanalytics::Model::StmtResource
        #         self.destroy_resource(original_resource_as_hash, processed_resource)
        #       when Lanalytics::Model::ResourceRelationship
        #         self.merge_relationship(original_resource_as_hash, processed_resource)
        #       else
        #         puts "'processed_resource' (#{processed_resource.class.name}) could not be mapped to an operation"
        #       end
        #     else
        #       puts "'processed_resource' (#{processed_resource.class.name}) could not be mapped to an operation"
        #     end

        #   end
        # end

        # def merge_resource(original_resource_as_hash, resource)
        #   resource_type = resource.type
        #   resource_uuid = resource.uuid
        #   resource_properties = resource.properties.merge({ resource_uuid: resource_uuid })
        #   # ::TODO This is not beautiful, but necessary for the moment; Neo4jrb is not able to deal with nil values
        #   resource_properties.delete_if {|key, value| value.nil? }
        #   Neo4j::Session.query
        #     .merge(r: {resource_type => {resource_uuid: resource_uuid }})
        #     .on_create_set(r: resource_properties)
        #     .on_match_set(r: resource_properties)
        #     .exec
        # end

        # def merge_relationship(original_resource_as_hash, resource_relationship)

        #   resource_relationship.properties.delete_if {|key, value| value.nil? }
        #   # resource_relationship_properties = resource_relationship.properties
        #   # relationship_properties = relationship.except(*%w(with_rel_type to_resource_type to_resource_uuid))
        #   # ::TODO:: Issue this as a github issue
        #   Neo4j::Session.query
        #     .merge(r1: {resource_relationship.from_resource.type.to_sym => {resource_uuid: resource_relationship.from_resource.uuid }}).break
        #     .merge(r2: {resource_relationship.to_resource.type.to_sym => {resource_uuid: resource_relationship.to_resource.uuid }}).break
        #     .merge("(r1)-[:#{resource_relationship.type} #{Neo4j::Core::Query.new.merge(resource_relationship.properties).to_cypher[8..-2]}]->(r2)")
        #     .exec
        # end

        # def create_experience_statement(original_resource_as_hash, exp_stmt)

        #   relationship_properties = {}
        #   relationship_properties[:timestamp] = exp_stmt.properties[:timestamp]
        #   exp_stmt.properties[:with_result].each { | k, v | relationship_properties["result_#{k}".to_sym] = v }
        #   exp_stmt.properties[:in_context].each { | k, v | relationship_properties["context_#{k}".to_sym] = v }


        #   Neo4j::Session.query
        #   .merge(r1: {exp_stmt.user.type => { resource_uuid: exp_stmt.user.uuid }}).break
        #   .merge(r2: {exp_stmt.resource.type => { resource_uuid: exp_stmt.resource.uuid }}).break
        #   .create("(r1)-[:#{exp_stmt.verb.type} #{Neo4j::Core::Query.new.merge(relationship_properties).to_cypher[8..-2]}]->(r2)")
        #   .exec
        # end

        # def destroy_resource(original_resource_as_hash, resource)
        #   resource_type = resource.type
        #   resource_uuid = resource.uuid
        #   Neo4j::Session.query
        #     .match(r: {resource_type => {resource_uuid: resource_uuid }})
        #     .delete(:r)
        #     .exec
        # end
      end
    end
  end
end
