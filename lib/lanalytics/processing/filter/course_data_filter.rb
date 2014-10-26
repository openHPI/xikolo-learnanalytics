module Lanalytics
  module Processing
    module Filter
      
      class CourseDataFilter < Lanalytics::Processing::ProcessingStep
        def filter(original_resource_as_hash, processed_resources, opts = nil)
          processed_resources << Lanalytics::Model::StmtResource.new(:COURSE, original_resource_as_hash[:id], original_resource_as_hash.slice(:title, :course_code, :start_date, :end_date))    
        end
      end
    
    end
  end
end
