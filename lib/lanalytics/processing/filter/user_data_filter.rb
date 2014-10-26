module Lanalytics
  module Processing
    module Filter
      
      class UserDataFilter < Lanalytics::Processing::ProcessingStep
        def filter(original_resource_as_hash, processed_resources, opts = nil)

          uninteresting_properties = [:id, :emails_url, :email_url, :self_url, :blurb_url, :legacy_id, :fields]

          resource_properties = original_resource_as_hash.except(*uninteresting_properties)
          
          if original_resource_as_hash.key?(:fields) and not original_resource_as_hash[:fields].nil?
            original_resource_as_hash[:fields].each do | field_hash |
              field_hash = field_hash.with_indifferent_access
              field_name = field_hash[:name]
              field_value = field_hash[:values].first
              resource_properties[field_name] = field_value unless field_value.nil? or field_value.blank?
            end
          end

          processed_resources << Lanalytics::Model::StmtResource.new(:USER, original_resource_as_hash[:id], resource_properties)    
        end
        alias_method :process, :filter
      end
    
    end
  end
end
