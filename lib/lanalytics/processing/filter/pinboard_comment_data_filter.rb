module Lanalytics
  module Processing
    module Filter
      
      class PinboardCommentDataFilter < Lanalytics::Processing::ProcessingStep
        
        def filter(original_resource_as_hash, processed_resources, opts = nil)
          
          from_resource =  Lanalytics::Model::StmtResource.new(:USER, original_resource_as_hash[:user_id])

          to_resource = Lanalytics::Model::StmtResource.new(original_resource_as_hash[:commentable_type].to_sym.upcase, original_resource_as_hash[:commentable_id])

          relationship_properties = original_resource_as_hash.except(:user_id, :id, :commentable_id, :commentable_type)

          processed_resources << Lanalytics::Model::ResourceRelationship.new(from_resource, :COMMENTED, to_resource, relationship_properties)
        end
        alias_method :process, :filter

      end
    
    end
  end
end
