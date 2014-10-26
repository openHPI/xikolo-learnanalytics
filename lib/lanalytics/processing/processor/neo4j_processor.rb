module Lanalytics
  module Processing
    module Processor
      class Neo4jProcessor < Lanalytics::Processing::ProcessingStep
          
        def process(original_resource_as_hash, processed_resources, opts = {})
          
          if processed_resources.nil? or processed_resources.empty?
            puts "'processed_resources' cannot be nil or empty"
            return
          end

          processed_resources.each do | processed_resource |
            
            if opts[:processing_action] == Lanalytics::Processing::ProcessingAction::CREATE or
              opts[:processing_action] == Lanalytics::Processing::ProcessingAction::UPDATE
              case processed_resource
              when Lanalytics::Model::StmtResource
                self.merge_resource(original_resource_as_hash, processed_resource)
              when Lanalytics::Model::ResourceRelationship
                self.merge_relationship(original_resource_as_hash, processed_resource)
              when Lanalytics::Model::ExpApiStatement
                self.create_experience_statement(original_resource_as_hash, processed_resource)
              else
                puts "'processed_resource' (#{processed_resource.class.name}) could not be mapped to an operation"
              end
            elsif opts[:processing_action] == Lanalytics::Processing::ProcessingAction::DESTROY
              case processed_resource
              when Lanalytics::Model::StmtResource
                self.destroy_resource(original_resource_as_hash, processed_resource)
              when Lanalytics::Model::ResourceRelationship
                self.merge_relationship(original_resource_as_hash, processed_resource)
              else
                puts "'processed_resource' (#{processed_resource.class.name}) could not be mapped to an operation"
              end
            else
              puts "'processed_resource' (#{processed_resource.class.name}) could not be mapped to an operation"
            end

          end
        end

        def merge_resource(original_resource_as_hash, resource)

          resource_type = resource.type
          resource_uuid = resource.uuid
          resource_properties = resource.properties.merge({ resource_uuid: resource_uuid })
          # ::TODO This is not beautiful, but necessary for the moment; Neo4jrb is not able to deal with nil values
          resource_properties.delete_if {|key, value| value.nil? }
          Neo4j::Session.query
            .merge(r: {resource_type => {resource_uuid: resource_uuid }})
            .on_create_set(r: resource_properties)
            .on_match_set(r: resource_properties)
            .exec
        end

        def merge_relationship(original_resource_as_hash, resource_relationship)

          # resource_relationship_properties = resource_relationship.properties
          # relationship_properties = relationship.except(*%w(with_rel_type to_resource_type to_resource_uuid))
          # ::TODO:: Issue this as a github issue
          Neo4j::Session.query
            .merge(r1: {resource_relationship.from_resource.type.to_sym => {resource_uuid: resource_relationship.from_resource.uuid }}).break
            .merge(r2: {resource_relationship.to_resource.type.to_sym => {resource_uuid: resource_relationship.to_resource.uuid }}).break
            .merge("(r1)-[:#{resource_relationship.type} #{Neo4j::Core::Query.new.merge(resource_relationship.properties).to_cypher[8..-2]}]->(r2)")
            .exec
        end

        def create_experience_statement(original_resource_as_hash, exp_stmt)
          Neo4j::Session.query
          .merge(r1: {exp_stmt.user.type => { resource_uuid: exp_stmt.user.uuid }}).break
          .merge(r2: {exp_stmt.resource.type => { resource_uuid: exp_stmt.resource.uuid }}).break
          .create("(r1)-[:#{exp_stmt.verb.type} #{Neo4j::Core::Query.new.merge(exp_stmt.with_result).to_cypher[8..-2]}]->(r2)")
          .exec
        end

        def destroy_resource(original_resource_as_hash, resource)
          resource_type = resource.type
          resource_uuid = resource.uuid
          Neo4j::Session.query
            .match(r: {resource_type => {resource_uuid: resource_uuid }})
            .delete(:r)
            .exec
        end
      end
    end
  end
end
