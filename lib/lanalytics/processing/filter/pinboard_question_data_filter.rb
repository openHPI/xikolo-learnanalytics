module Lanalytics
  module Processing
    module Filter
  
      class PinboardQuestionDataFilter < Lanalytics::Processing::ProcessingStep
        def filter(original_resource_as_hash, processed_resources, opts = {})

          from_resource_properties = original_resource_as_hash.slice(:title, :text, :sticky, :deleted, :closed, :discussion_flag, :created_at, :updated_at, :user_tags).with_indifferent_access
          from_resource = Lanalytics::Model::StmtResource.new(:QUESTION, original_resource_as_hash[:id], from_resource_properties)    
          processed_resources << from_resource

          # Define relationship between :USER resource and :QUESTION
          processed_resources << Lanalytics::Model::ResourceRelationship.new(Lanalytics::Model::StmtResource.new(:USER, original_resource_as_hash[:user_id]), :POSTED, from_resource, {created_at: original_resource_as_hash[:created_at]})

          if original_resource_as_hash[:course_id]
            
            processed_resources << Lanalytics::Model::ResourceRelationship.new(from_resource, :BELONGS_TO, Lanalytics::Model::StmtResource.new(:COURSE, original_resource_as_hash[:course_id]))

          elsif original_resource_as_hash[:learning_room_id]
            
            processed_resources << Lanalytics::Model::ResourceRelationship.new(from_resource, :BELONGS_TO, Lanalytics::Model::StmtResource.new(:LEARNING_ROOM, original_resource_as_hash[:learning_room_id]))
          
          else
            Rails.logger.info 'No connection could be found to :COURSE or :LEARNING_ROOM'
          end


        end
        alias_method :process, :filter
      end
      
    end
  end
end
