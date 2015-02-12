require 'time'

module Lanalytics
  module Processing
    class ProfilingPipeline < Pipeline

      def initialize(name, schema, processing_action, extractors = [], transformers = [], loaders = [], &block)
        super(name, schema, processing_action, extractors = [], transformers = [], loaders = [], &block)
        @processing_count = 0
        @total_processing_time_in_lanalytics = 0
      end

      def process(original_event, processing_opts = {})

        @processing_count += 1
        processing_start_time = Time.now



        processing_opts ||= {}

        unless original_event
          Rails.logger.info 'Data that should be imported is nil; there is nothing to process ...'
          return
        end

        original_event = original_event.with_indifferent_access

        pipeline_ctx = PipelineContext.new(self, processing_opts)

        processing_units = []
        @extractors.each do | extractor |
          extractor.extract(original_event, processing_units, pipeline_ctx)
        end

        # Take care of 'processing_units' and 'load_commands' because these arrays are mutable and are modified in the transformation steps
        load_commands = []
        @transformers.each do | transformer |
          transformer.transform(original_event, processing_units, load_commands, pipeline_ctx)
        end

        @loaders.each do | loader |
          loader.load(original_event, load_commands, pipeline_ctx)
        end



        processing_end_time = Time.now
        @total_processing_time_in_lanalytics += (processing_end_time - processing_start_time)
        # processing_time = processing_end_time - Time.parse(original_event[:timestamp])
        # @@total_processing_time_of_events += processing_time
        puts "Average Processing Time (in Pipeline '#{@schema}' LAnalytics Service) #{@total_processing_time_in_lanalytics/@processing_count}"
        # puts "Processing Time of event #{processing_end_time - Time.parse(original_event[:timestamp])}"
        # puts "Average Processing Time of event #{@@total_processing_time_of_events/@@processing_count}"
        
      end

    end
  end
end
