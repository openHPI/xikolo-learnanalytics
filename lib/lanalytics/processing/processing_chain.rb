module Lanalytics
  module Processing
    class ProcessingChain
      attr_reader :processing_steps

      def initialize(processing_steps = [])
        
        processing_steps ||= []

        processing_steps = [processing_steps] unless processing_steps.is_a? Array

        processing_steps.each do | processing_step |
          unless processing_step.is_a?(Lanalytics::Processing::ProcessingStep)
            raise ArgumentError.new("'processing_steps' should contain only subclasses of Lanalytics::Processing::ProcessingStep")
          end
        end

        @processing_steps = processing_steps
      end

      def process(data, processsing_opts = {})

        processsing_opts ||= {}

        unless data
          Rails.logger.info 'Nothing to import'
          return
        end

        data = data.with_indifferent_access

        # Take care this is mutable and is modified in the processing steps
        processed_resources = []
        @processing_steps.each do | processing_step |
          processing_step.process(data, processed_resources, processsing_opts)
        end

        return processed_resources
      end

    end
  end
end