# frozen_string_literal: true

module Lanalytics
  module Processing
    class PipelineManager
      include Singleton

      def self.setup_pipelines(pipelines_setup_file)
        raise ArgumentError.new 'Given pipelines_setup_file cannot be nil!' unless pipelines_setup_file

        unless File.exist?(pipelines_setup_file)
          raise ArgumentError.new "File '#{pipelines_setup_file}' does not exist."
        end

        unless File.extname(pipelines_setup_file) == '.prb'
          raise ArgumentError.new "File '#{pipelines_setup_file}' has to end with 'prb'."
        end

        begin
          instance.instance_eval(File.read(pipelines_setup_file))
        rescue SyntaxError => e
          raise "The following error occurred when registering pipeline #{pipelines_setup_file}: #{e.message}"
        end

        instance
      end

      def initialize
        @pipelines = Hash.new do |hash, key|
          hash[key] = {
            Lanalytics::Processing::Action::CREATE => {},
            Lanalytics::Processing::Action::UPDATE => {},
            Lanalytics::Processing::Action::DESTROY => {},
          }
        end
      end

      def register_pipeline(pipeline)
        @pipelines[pipeline.schema][pipeline.processing_action][pipeline.name] = pipeline

        Rails.logger.debug do
          "Registered pipeline '#{pipeline.name}' in schema '#{pipeline.schema}' and for processing " \
            "action '#{pipeline.processing_action}'"
        end
      end

      def pipeline_for(name, schema, processing_action, &)
        @pipelines[schema][processing_action][name] = Pipeline.new(
          name,
          schema,
          processing_action,
          &
        )

        Rails.logger.debug do
          "Registered pipeline '#{name}' in schema '#{schema}' and for processing action '#{processing_action}'"
        end
      end

      # -----------------------
      # Access methods for the registered pipelines
      # -----------------------

      # Look in all schemas for the pipeline name
      def schema_pipelines_with(processing_action, pipeline_name)
        pipelines = {}

        @pipelines.each do |schema_key, schema_pipelines|
          next unless schema_pipelines.include?(processing_action)
          next unless schema_pipelines[processing_action].include?(pipeline_name)

          pipelines[schema_key] = schema_pipelines[processing_action][pipeline_name]
        end

        pipelines
      end

      def find_piplines(schema, processing_action, pipeline_name)
        return schema_pipelines_with(processing_action, pipeline_name).values if schema.blank?

        pipeline = @pipelines[schema.to_sym][processing_action.to_sym][pipeline_name.to_s]

        return [] unless pipeline

        [pipeline]
      end
    end
  end
end
