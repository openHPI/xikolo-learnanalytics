module Lanalytics
  module Processing
    module Filter
      
      class MembershipDataFilter < Lanalytics::Processing::ProcessingStep
        
        def initialize(from_resource_sym, to_resource_sym, relationship_type = :BELONGS_TO)
          
          raise ArgumentError.new("'from_resource_sym' cannot be nil") unless from_resource_sym
          @from_resource_id_key = from_resource_sym
          @from_resource_type = type_from(from_resource_sym)

          raise ArgumentError.new("'to_resource_sym' cannot be nil") unless to_resource_sym
          @to_resource_id_key = to_resource_sym
          @to_resource_type = type_from(to_resource_sym)

          
          raise ArgumentError.new("'to_resource_sym' cannot be nil") unless to_resource_sym
          relationship_type ||= :BELONGS_TO
          @relationship_type = relationship_type
        end

        def filter(original_resource_as_hash, processed_resources, opts = nil)
          
          from_resource =  Lanalytics::Model::StmtResource.new(@from_resource_type, original_resource_as_hash[@from_resource_id_key])

          to_resource = Lanalytics::Model::StmtResource.new(@to_resource_type, original_resource_as_hash[@to_resource_id_key])

          relationship_properties = original_resource_as_hash.except(@from_resource_id_key, @to_resource_id_key, :id)

          processed_resources << Lanalytics::Model::ResourceRelationship.new(from_resource, @relationship_type, to_resource, relationship_properties)
        end
        alias_method :process, :filter

        private
        def type_from(resource_sym)

          resource_type_match = /^(?<resource_type>.*)_\w+$/.match(resource_sym.to_s)

          raise ArgumentError.new("Cannot find resource type in 'resource_sym' = #{resource_sym}") if resource_type_match.nil? or resource_type_match[:resource_type].nil? or resource_type_match[:resource_type].empty?
          
          return resource_type_match[:resource_type].to_sym.upcase
        end

      end
    
    end
  end
end
