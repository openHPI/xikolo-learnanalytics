module Lanalytics
  module Processing
    # TODO:: Rename to Lanalytics::Processing::Action
    class ProcessingAction
      CREATE    = :CREATE
      UPDATE    = :UPDATE
      DESTROY   = :DESTROY
      UNDEFINED = :UNDEFINED

      def self.valid(processing_action_to_check)
        (
          processing_action_to_check.instance_of?(Symbol) && (
            processing_action_to_check == CREATE ||
            processing_action_to_check == UPDATE ||
            processing_action_to_check == DESTROY ||
            processing_action_to_check == UNDEFINED
          )
        )
      end
    end
  end
end
