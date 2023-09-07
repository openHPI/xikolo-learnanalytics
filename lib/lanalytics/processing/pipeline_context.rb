# frozen_string_literal: true

module Lanalytics
  module Processing
    class PipelineContext
      attr_reader :pipeline

      def initialize(pipeline, opts = {})
        @pipeline = pipeline

        opts ||= {}
        @opts = opts
      end

      def name
        @pipeline.name
      end

      def processing_action
        @pipeline.processing_action
      end
    end
  end
end
