module Lanalytics
  module Processing
    # TODO:: Rename to Lanalytics::Processing::Action
    class ProcessingAction
      CREATE = :CREATE
      UPDATE = :UPDATE
      DESTROY = :DESTROY
      UNDEFINED = :UNDEFINED

      def self.valid(processing_action_to_check)
        return (
          processing_action_to_check.instance_of?(Symbol) and (
            processing_action_to_check == CREATE or
            processing_action_to_check == UPDATE or
            processing_action_to_check == DESTROY or
            processing_action_to_check == UNDEFINED
        )) 

      end
    end
  end
end