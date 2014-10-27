module Lanalytics
  module Processing
    module Filter
      
      class ExpApiStatementDataFilter < Lanalytics::Processing::ProcessingStep
        def filter(original_resource_as_hash, processed_resources, opts = {})
          exp_stmt = Lanalytics::Model::ExpApiStatement.new_from_json(original_resource_as_hash)
          processed_resources << exp_stmt
          opts[:processing_action] = Lanalytics::Processing::ProcessingAction::CREATE
        end
        alias_method :process, :filter
      end

    end
  end
end