module Lanalytics
  module Processing
    module Transformer
      module NosqlDataSchemaHelper

        # Helper method for transformation of entities
        def new_entity_template(processing_unit, allowed_properties = nil)
          entity_key = processing_unit.type.upcase.to_sym
          entity = Lanalytics::Processing::LoadORM::Entity.create(entity_key) do
            with_primary_attribute :resource_uuid, :string, processing_unit[:id]

            processing_unit_data = processing_unit.data.except(:id)
            if allowed_properties
              processing_unit_data = processing_unit_data.slice(*allowed_properties)
            end

            processing_unit_data.each do |property, value|
              with_attribute property.downcase.to_sym, :string, value
            end
          end

          entity
        end

        def handle_directed_relationship(
          processing_unit,
          relationship_key,
          from_entity_property_key,
          to_entity_property_key
        )
          from_entity_key = type_from(from_entity_property_key).to_sym.upcase
          to_entity_key = type_from(to_entity_property_key).to_sym.upcase

          Lanalytics::Processing::LoadORM::EntityRelationship.create(relationship_key) do
            with_primary_attribute :relationship_uuid, :string, processing_unit[:id]

            with_from_entity(from_entity_key) do
              with_primary_attribute :resource_uuid, :uuid, processing_unit[from_entity_property_key]
            end

            with_to_entity(to_entity_key) do
              with_primary_attribute :resource_uuid, :uuid, processing_unit[to_entity_property_key]
            end

            processing_unit.data.except(
              :id,
              from_entity_property_key,
              to_entity_property_key
            ).each do |property, value|
              with_attribute property.downcase.to_sym, :string, value
            end
          end
        end

        private

        def type_from(property_key)
          entity_key_match = /^(?<entity_key>\w+)_\w+$/.match(property_key.to_s)

          if entity_key_match.nil? ||
             entity_key_match[:entity_key].nil? ||
             entity_key_match[:entity_key].empty?
            fail ArgumentError, "Cannot find resource type in 'property_key' = #{property_key}"
          end

          entity_key_match[:entity_key]
        end

      end
    end
  end
end
