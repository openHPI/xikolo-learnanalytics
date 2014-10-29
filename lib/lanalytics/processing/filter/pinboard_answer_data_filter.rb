module Lanalytics
  module Processing
    module Filter
  
      class PinboardAnswerDataFilter < Lanalytics::Processing::ProcessingStep
        def filter(original_resource_as_hash, processed_resources, opts = {})

          from_resource_properties = original_resource_as_hash.slice(:text, :created_at, :updated_at).with_indifferent_access
          from_resource = Lanalytics::Model::StmtResource.new(:ANSWER, original_resource_as_hash[:id], from_resource_properties)    
          processed_resources << from_resource

          # Define relationship between :USER resource and the :ANSWER resource
          processed_resources << Lanalytics::Model::ResourceRelationship.new(Lanalytics::Model::StmtResource.new(:USER, original_resource_as_hash[:user_id]), :POSTED_ANSWER, from_resource, {created_at: original_resource_as_hash[:created_at]})

          processed_resources << Lanalytics::Model::ResourceRelationship.new(from_resource, :BELONGS_TO, Lanalytics::Model::StmtResource.new(:QUESTION, original_resource_as_hash[:question_id]))

        end
        alias_method :process, :filter
      end
      
    end
  end
end
