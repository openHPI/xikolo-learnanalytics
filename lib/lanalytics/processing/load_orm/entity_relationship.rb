module Lanalytics
  module Processing
    module LoadORM
      class EntityRelationship < Entity
        attr_reader :relationship_key, :from_entity, :to_entity

        def self.create(relationship_key, &block)
          relationship = self.new(relationship_key)
          relationship.instance_eval(&block)
          
          raise "Relationship needs a from_entity and a to_entity" unless relationship.from_entity and relationship.to_entity

          return relationship
        end

        def initialize(relationship_key)
          @relationship_key, @attributes = relationship_key, []
        end

        def with_from_entity(entity_key, &block)
          @from_entity = Entity.create(entity_key, &block)
        end

        def with_to_entity(entity_key, &block)
          @to_entity = Entity.create(entity_key, &block)
        end
      end
    end
  end
end