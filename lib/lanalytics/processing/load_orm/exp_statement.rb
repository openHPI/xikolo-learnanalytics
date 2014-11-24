module Lanalytics
  module Processing
    module LoadORM

      class ExperienceStatement < EntityRelationship

        def self.new_from_json(json)

          self.create(json[:verb][:type].upcase.to_sym) do
            
            with_from_entity(:USER) do
              with_primary_attribute :resource_uuid, :uuid, exp_stmt.user.uuid
            end

            with_to_entity(exp_stmt.resource.type) do
              with_primary_attribute :resource_uuid, :uuid, exp_stmt.resource.uuid
            end

            with_attribute :timestamp, :datetime, exp_stmt.timestamp
            
            exp_stmt.with_result.each do | attribute, value |
              with_attribute "with_result_#{attribute.underscore.downcase}", :string, value
            end

            exp_stmt.in_context.each do | attribute, value |
              with_attribute "in_context_#{attribute.underscore.downcase}", :string, value
            end
          end

        end

      end

    end
  end
end