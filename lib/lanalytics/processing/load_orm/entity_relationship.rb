# frozen_string_literal: true

module Lanalytics
  module Processing
    module LoadORM
      class EntityRelationship < Entity
        attr_reader :relationship_key, :from_entity, :to_entity

        def self.create(relationship_key, &)
          relationship = new(relationship_key)
          relationship.instance_eval(&)

          unless relationship.from_entity && relationship.to_entity
            raise 'Relationship needs a from_entity and a to_entity'
          end

          relationship
        end

        def initialize(relationship_key) # rubocop:disable Lint/MissingSuper
          @relationship_key = relationship_key
          @attributes       = []
        end

        def with_from_entity(entity_key, &)
          @from_entity = Entity.create(entity_key, &)
        end

        def with_to_entity(entity_key, &)
          @to_entity = Entity.create(entity_key, &)
        end
      end
    end
  end
end
