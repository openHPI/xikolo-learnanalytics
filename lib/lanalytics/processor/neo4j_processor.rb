module Lanalytics
  module Processor
    class Neo4jProcessor < Lanalytics::Processor::DataProcessor
        
      def process(original_resource_as_hash, processed_resources, opts = nil)
        
        if processed_resources.nil? or processed_resources.empty?
          puts "'processed_resources' cannot be nil or empty"
          return
        end

        processed_resources.each do | processed_resource |

          case processed_resource
          when Lanalytics::Model::StmtResource
            self.create_or_update_resource(original_resource_as_hash, processed_resource)
          when Lanalytics::Model::ResourceRelationship
            self.create_or_update_relationship(original_resource_as_hash, processed_resource)
          else
            puts "'processed_resource' (#{processed_resource.class.name}) could not be mapped to an operation"
          end
        end
      end

      def create_or_update_resource(original_resource_as_hash, resource)

        ressource_type = resource.type
        ressource_uuid = resource.uuid
        ressource_properties = resource.properties.merge({ ressource_uuid: ressource_uuid })
        # ::TODO This is not beautiful, but necessary for the moment; Neo4jrb is not able to deal with nil values
        ressource_properties.delete_if {|key, value| value.nil? }
        Neo4j::Session.query
          .merge(r: {ressource_type => {ressource_uuid: ressource_uuid }})
          .on_create_set(r: ressource_properties)
          .on_match_set(r: ressource_properties)
          .exec
      end

      def create_or_update_relationship(original_resource_as_hash, resource_relationship)

        # resource_relationship_properties = resource_relationship.properties
        # relationship_properties = relationship.except(*%w(with_rel_type to_ressource_type to_ressource_uuid))
        # ::TODO:: Issue this as a github issue
        Neo4j::Session.query
          .merge(r1: {resource_relationship.from_resource.type.to_sym => {ressource_uuid: resource_relationship.from_resource.uuid }}).break
          .merge(r2: {resource_relationship.to_resource.type.to_sym => {ressource_uuid: resource_relationship.to_resource.uuid }}).break
          .merge("(r1)-[:#{resource_relationship.type} #{Neo4j::Core::Query.new.merge(resource_relationship.properties).to_cypher[8..-2]}]->(r2)")
          .exec
      end

      # def update

      #     ressource_type = payload[:ressource_type]
      #     ressource = payload[:ressource].with_indifferent_access
      #     ressource_uuid = ressource[:ressource_uuid]
      #     ressource_properties = ressource.except(:relationships)
      #     # ::TODO This is not beautiful, but necessary for the moment; Neo4jrb is not able to deal with nil values
      #     ressource_properties.delete_if {|key, value| value.nil? }
      #     Neo4j::Session.query
      #       .merge(r: {ressource_type.to_sym => {ressource_uuid: ressource_uuid }})
      #       .on_create_set(r: ressource_properties)
      #       .on_match_set(r: ressource_properties)
      #       .pluck(:r)

      #     if ressource.has_key?(:relationships) and not ressource[:relationships].nil? and not ressource[:relationships].empty?
      #       for relationship in ressource[:relationships]
      #         relationship_properties = relationship.except(*%w(with_rel_type to_ressource_type to_ressource_uuid))
      #         # ::TODO:: Issue this as a github issue
      #         Neo4j::Session.query
      #           .merge(r1: {ressource_type.to_sym => {ressource_uuid: ressource[:ressource_uuid] }}).break
      #           .merge(r2: {relationship[:to_ressource_type].to_sym => {ressource_uuid: relationship[:to_ressource_uuid] }}).break
      #           .merge("(r1)-[:#{relationship[:with_rel_type]} #{Neo4j::Core::Query.new.merge(relationship_properties).to_cypher[8..-2]}]->(r2)")
      #           .pluck(:r1)
      #       end
      #     end
      #   end
      # end


    end
  end
end
