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

      # def add_processing_for(routing_key, processing_steps)
      #   raise ArgumentError.new("'routing key' cannot be nil") if routing_key.nil?

      #   processing_chain = Lanalytics::Processing::ProcessingChain.new(processing_steps)
      #   @processing_map[routing_key.to_s] = processing_chain
      #   Rails.logger.info "Registered processing chain (#{processing_chain.processing_steps}) for routing key: #{routing_key}"
      # end

      # def process_data_for(routing_key, payload, opts = {})

      #   processing_chain = @processing_map[routing_key.to_s]
      #   unless processing_chain
      #     Rails.logger.warn "No processing found for routing key: #{routing_key}"
      #     return
      #   end

      #   if routing_key.end_with?('.create')
      #     opts.merge!({ processing_action: Lanalytics::Processing::ProcessingAction::CREATE })
      #   elsif routing_key.end_with?('.update')
      #     opts.merge!({ processing_action: Lanalytics::Processing::ProcessingAction::UPDATE })
      #   elsif routing_key.end_with?('.destroy')
      #     opts.merge!({ processing_action: Lanalytics::Processing::ProcessingAction::DESTROY })
      #   else
      #     opts.merge!({ processing_action: Lanalytics::Processing::ProcessingAction::UNDEFINED })
      #   end

      #   processing_chain.process(payload, opts)
      # end



    end
  end
end