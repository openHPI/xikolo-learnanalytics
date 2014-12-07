module Lanalytics
  module Processing
    class PipelineManager
      include Singleton

      def self.setup_pipelines(pipelines_dir = "#{Rails.root}/config/pipelines")

        Dir.glob("#{pipelines_dir}/*_pipeline.rb") do | pipeline_file_name |
          # raise ArgumentError.new "File `#{file}` does not exists." unless File.exists? file
          self.instance.instance_eval(File.read(pipeline_file_name))
        end

        return self.instance
      end

      def initialize()
        @pipelines = Hash.new do |hash, key|
          hash[key] = { 
            Lanalytics::Processing::ProcessingAction::CREATE => Hash.new,
            Lanalytics::Processing::ProcessingAction::UPDATE => Hash.new,
            Lanalytics::Processing::ProcessingAction::DESTROY => Hash.new
          }
        end
      end

      def pipeline_for(name, schema, processing_action, &block)
        @pipelines[schema][processing_action][name] = Pipeline.new(name, schema, processing_action, &block)
        Rails.logger.info "Registered pipeline '#{name}' in schema '#{schema}' and for processing action '#{processing_action}'"
      end

      # Look in all schemas for the pipeline name
      def schema_pipelines_with(processing_action, pipeline_name)

        pipelines = Hash.new
   
        @pipelines.each do | schema_key, schema_pipelines |
          if schema_pipeline = schema_pipelines[processing_action].fetch(pipeline_name, false)
            pipelines[schema_key] = schema_pipeline
          end
        end

        return pipelines
      end

      def find_piplines(schema, processing_action, pipeline_name)

        if schema.nil? or schema.empty?
          return schema_pipelines_with(processing_action, pipeline_name).values
        end
        pipeline = @pipelines[schema.to_sym][processing_action.to_sym][pipeline_name.to_s]
        
        return [] unless pipeline

        return [pipeline]
      end
    end
  end
end