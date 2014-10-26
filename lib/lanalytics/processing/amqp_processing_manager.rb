module Lanalytics
  module Processing
    class AmqpProcessingManager
      include Singleton

      def initialize()
        @processing_map = Hash.new()
      end

      def add_processing_for(routing_key, processing_steps)
        raise ArgumentError.new("'routing key' cannot be nil") if routing_key.nil?

        processing_chain = Lanalytics::Processing::ProcessingChain.new(processing_steps)
        @processing_map[routing_key.to_s] = processing_chain
        Rails.logger.info "Registered processing chain (#{processing_chain.processing_steps}) for routing key: #{routing_key}"
      end

      def process_data_for(routing_key, payload, opts = {})

        processing_chain = @processing_map[routing_key.to_s]
        unless processing_chain
          Rails.logger.warn "No processing found for routing key: #{routing_key}"
          return
        end

        processing_chain.process(payload, opts)
      end

      def self.load_processing_definitions(yml_file_name = "#{Rails.root}/config/processing.yml")

        processing_definitions = YAML.load_file(yml_file_name)

        processing_definitions.each do | processing_definition_key, processing_steps |

          if processing_definition_key.end_with?(*%w(.create .update .destroy))
            processing_steps.map! do | processing_step |
              # Some processing steps are not loaded during 'YAML.load_file'; that's why we are evaluating this in ruby
              processing_step = eval(processing_step) if processing_step.is_a?(String)
              processing_step
            end
            self.instance.add_processing_for(processing_definition_key, processing_steps)
          end
        end        

        return self.instance

      end
    end
  end
end