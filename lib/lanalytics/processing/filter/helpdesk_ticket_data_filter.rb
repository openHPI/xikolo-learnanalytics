module Lanalytics
  module Processing
    module Filter
  
      class HelpdeskTicketDataFilter < Lanalytics::Processing::ProcessingStep
        def filter(original_resource_as_hash, processed_resources, opts = {})

          Lanalytics::Processing::Filter::MembershipDataFilter.new(:user_id, :course_id, :SUBMITTED_FEEDBACK).filter(original_resource_as_hash, processed_resources, opts)

          puts processed_resources.inspect

          Lanalytics::Processing::Filter::AnonymousDataFilter.new.filter(original_resource_as_hash, processed_resources, opts)

          puts processed_resources.inspect
        end
        alias_method :process, :filter
      end
      
    end
  end
end
