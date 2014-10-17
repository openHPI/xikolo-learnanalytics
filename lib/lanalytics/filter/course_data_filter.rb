module Lanalytics
  module Filter
    
    class CourseDataFilter < Lanalytics::Filter::DataFilter
      def filter(datasource, original_resource_as_hash, processed_resources, opts = nil)
        processed_resources << Lanalytics::Model::StmtResource.new(:COURSE, original_resource_as_hash[:id], original_resource_as_hash.slice(:title, :course_code, :start_date, :end_date))    
      end
    end
  
  end
end
