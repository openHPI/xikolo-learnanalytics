module Lanalytics
  module Filter
    class ExpApiStatementDataFilter < Lanalytics::Filter::DataFilter

      def filter(original_resource_as_hash, processed_resources, opts = {})
        exp_stmt = Lanalytics::Model::ExpApiStatement.new_from_json(original_resource_as_hash)
        processed_resources << exp_stmt
        opts[:import_action] = Lanalytics::Processor::ProcessingAction::CREATE
      end

    end
  end
end