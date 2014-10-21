module Lanalytics
  module Filter
    
    class UserDataFilter < Lanalytics::Filter::DataFilter
      def filter(original_resource_as_hash, processed_resources, opts = nil)
        processed_resources << Lanalytics::Model::StmtResource.new(:USER, original_resource_as_hash[:id], original_resource_as_hash.except(:id, :emails_url, :email_url, :self_url, :blurb_url, :image_id, :legacy_id))    
      end
    end
  
  end
end
