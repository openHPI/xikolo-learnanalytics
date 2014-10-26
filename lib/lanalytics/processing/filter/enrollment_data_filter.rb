module Lanalytics
  module Processing
    module Filter
      
      class EnrollmentDataFilter < Lanalytics::Processing::ProcessingStep
        def filter(original_resource_as_hash, processed_resources, opts = nil)
          processed_resources << Lanalytics::Model::ResourceRelationship.new(
            Lanalytics::Model::StmtResource.new(:USER, original_resource_as_hash[:user_id]),
            :ATTENDING,
            Lanalytics::Model::StmtResource.new(:COURSE, original_resource_as_hash[:course_id]),
            original_resource_as_hash.slice(:role, :created_at))
        end
        alias_method :process, :filter
      end
    
    end
  end
end
