module Lanalytics
  module Processing
    module LoadORM
      class EntityRelationship < Entity
        attr_reader :relationship_key, :from_entity, :to_entity

        def self.create(relationship_key, &block)
          relationship = new(relationship_key)
          relationship.instance_eval(&block)

          unless relationship.from_entity && relationship.to_entity
            fail 'Relationship needs a from_entity and a to_entity'
          end

          relationship
        end

        def initialize(relationship_key)
          @relationship_key = relationship_key
          @attributes       = []
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
