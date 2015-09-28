module Lanalytics
  module Processing
    module Loader
      # TODO::Check naming of some variables in this class

      class Neo4jLoader < LoadStep

        def initialize(datasource = nil)
          @neo4j_datasource = datasource
        end

        def load(processing_unit, load_commands, pipeline_ctx)
          load_commands.each do |load_command|
            command = load_command.class.name.demodulize.underscore
            entity  = load_command.entity.class.name.demodulize.underscore

            begin
              method("do_#{command}_for_#{entity}").call(load_command)
            rescue StandardError => e
              Rails.logger.error { "Happened in pipeline '#{pipeline_ctx.pipeline.full_name}' for processing_unit: #{e.message}" }
              Rails.logger.error { processing_unit.inspect }
            end
          end
        end

        def to_resource_props(entity)
          Hash[
            entity.all_non_nil_attributes.map do |attr|
              [attr.name.to_s, attr.value.to_s]
            end
          ]
        end

        # ----------------------------------
        # HANDLING COMMANDS FOR ENTITIES (update, merge, destroy)
        #
        # TODO: Find out why begin and rescue is sometimes used, sometimes not.
        # TODO: Find out if entity create is included in update
        # ----------------------------------
        def do_merge_entity_command_for_entity(merge_entity_command)
          entity = merge_entity_command.entity

          resource_type  = entity.entity_key
          resource_props = to_resource_props(entity)

          begin
            @neo4j_datasource.exec do |session|
              neo4j_query = session
                            .query
                            .merge(
                              r: {
                                resource_type => {
                                  entity.primary_attribute.name => entity.primary_attribute.value
                                }
                              }
                            )
                            .on_create_set(r: resource_props)
                            .on_match_set(r: resource_props)

              neo4j_query.exec
            end
          rescue StandardError => e
            Rails.logger.error { "Following error occurred when executing a Cypher query on Neo4j: #{e.message}" }
            Rails.logger.error { "#{neo4j_query.to_cypher}" }

            throw e
          end
        end

        def do_update_command_for_entity(update_command)
          entity = update_command.entity
          resource_type = entity.entity_key
          resource_props = to_resource_props(entity)

          @neo4j_datasource.exec do |session|
            session
              .query
              .match(
                r: {
                  resource_type => {
                    entity.primary_attribute.name => entity.primary_attribute.value
                  }
                }
              )
              .set_props(r: resource_props)
              .exec
          end
          # .on_create_set(r: resource_props)
          # .on_match_set(r: resource_props)
        end

        def do_destroy_command_for_entity(destroy_command)
          entity = destroy_command.entity
          enitity_type = entity.entity_key

          @neo4j_datasource.exec do |session|
            session
              .query
              .match(
                e: {
                  enitity_type => {
                    entity.primary_attribute.name => entity.primary_attribute.value
                  }
                }
              )
              .delete(:e)
              .exec
          end
        end

        # ----------------------------------
        # HANDLING COMMANDS FOR ENTITY RELATIONSHIPS
        # ----------------------------------
        def do_create_command_for_entity_relationship(create_entity_command)
          create_update_merge_entity_relationship(create_entity_command, :create)
        end

        def do_merge_entity_command_for_entity_relationship(merge_entity_command)
          create_update_merge_entity_relationship(merge_entity_command, :merge)
        end

        def do_update_command_for_entity_relationship(update_command)
          do_merge_entity_command_for_entity_relationship(update_command)
        end

        def create_update_merge_entity_relationship(command, type)
          entity           = command.entity

          e1_key           = entity.from_entity.entity_key.name.to_sym
          e1_pattribute    = entity.from_entity.primary_attribute

          e2_key           = entity.to_entity.entity_key.to_sym
          e2_pattribute    = entity.to_entity.primary_attribute

          rel_key          = entity_rel.relationship_key
          props            = Neo4j::Core::Query.new
                             .merge(to_resource_props(entity))
                             .to_cypher[8..-2]

          @neo4j_datasource.exec do |session|
            query = session
                    .query
                    .merge(
                      e1: {
                        e1_key => {
                          e1_pattribute.name.to_sym => e1_pattribute.value.to_s
                        }
                      }
                    )
                    .break
                    .merge(
                      e2: {
                        e2_key => {
                          e2_pattribute.name.to_sym => e2_pattribute.value.to_s
                        }
                      }
                    )
                    .break

            if    type == :create
              query = query.create("(e1)-[:#{rel_key} #{props}]->(e2)")
            elsif type == :merge
              query = query.merge("(e1)-[:#{rel_key} #{props}]->(e2)")
            end

            query.exec
          end
        end

        def do_destroy_command_for_entity_relationship(destroy_command)
          entity  = destroy_command.entity
          rel_key = entity.relationship_key

          key   = entity.primary_attribute.name
          value = entity.primary_attribute.value.to_s

          @neo4j_datasource.exec do |session|
            session
              .query
              .match("()-[r:#{rel_key} {#{key}:\"#{value}\"}]->()")
              .delete(:r)
              .exec
          end
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
        #   resource_props = resource.properties.merge({ resource_uuid: resource_uuid })
        #   # ::TODO This is not beautiful, but necessary for the moment; Neo4jrb is not able to deal with nil values
        #   resource_props.delete_if {|key, value| value.nil? }
        #   Neo4j::Session.query
        #     .merge(r: {resource_type => {resource_uuid: resource_uuid }})
        #     .on_create_set(r: resource_props)
        #     .on_match_set(r: resource_props)
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
