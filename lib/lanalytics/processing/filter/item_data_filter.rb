module Lanalytics
  module Processing
    module Filter
      
      class ItemDataFilter < Lanalytics::Processing::ProcessingStep
        def filter(original_resource_as_hash, processed_resources, opts = nil)

          from_resource_properties = original_resource_as_hash.slice(:title, :content_type, :start_date, :end_date, :created_at, :updated_at)
          from_resource = Lanalytics::Model::StmtResource.new(:ITEM, original_resource_as_hash[:id], from_resource_properties)    
          processed_resources << from_resource

          to_resource = Lanalytics::Model::StmtResource.new(:COURSE, original_resource_as_hash[:course_id])    

          processed_resources << Lanalytics::Model::ResourceRelationship.new(from_resource, :BELONGS_TO, to_resource)

        end
        alias_method :process, :filter
      end
      
    end
  end
end
