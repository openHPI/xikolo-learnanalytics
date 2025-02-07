# frozen_string_literal: true

module Lanalytics
  module Processing
    class Action
      CREATE = :CREATE
      UPDATE = :UPDATE
      DESTROY = :DESTROY
      UNDEFINED = :UNDEFINED

      def self.valid(processing_action_to_check)
        processing_action_to_check.instance_of?(Symbol) &&
          [CREATE, UPDATE, DESTROY, UNDEFINED].include?(processing_action_to_check)
      end
    end
  end
end
