module Lanalytics
  module Processing
    class PipelineManager
      include Singleton

      def self.setup_pipelines(pipelines_setup_file)

        raise ArgumentError.new("Given pipelines_setup_file cannot be nil!") unless pipelines_setup_file
        raise ArgumentError.new "File '#{pipelines_setup_file}' does not exists." unless File.exists? pipelines_setup_file

        begin
          self.instance.instance_eval(File.read(pipelines_setup_file))
        rescue Exception => error
          raise "The following error occurred when registering pipeline #{pipelines_setup_file}: #{error.message}"
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

        # Comment in if you want to do some profiling 
        # if Rails.env.profiling?
        #   @pipelines[schema][processing_action][name] = ProfilingPipeline.new(name, schema, processing_action, &block)
        # end

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