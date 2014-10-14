module Lanalytics
  module Filter
    
    class ItemDataFilter < Lanalytics::Filter::DataFilter
      def filter(datasource, original_resource_as_hash, processed_resource)

        respurce1_properties = original_resource_as_hash.slice(:title, :content_type, :start_date, :end_date, :created_at, :updated_at)
        resource1 = Lanalytics::Model::StmtResource.new(:ITEM, original_resource_as_hash[:id], respurce1_properties)    

        resource2 = Lanalytics::Model::StmtResource.new(:COURSE, original_resource_as_hash[:course_id])    
        relationship = Lanalytics::Model::ResourceRelationship.new(resource1, :BELONGS_TO, resource2)

        return [resource1, relationship]
      end
    end
  
  end
end
