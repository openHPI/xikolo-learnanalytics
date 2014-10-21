module Lanalytics
  # ::TODO:: Rename to Lanalytics::RabbitMQProcessingManager
  class Processing
    include Singleton

    def initialize()
      @processing_map = Hash.new()
    end

    def add_processing_for(routing_key, filters, processors)
      raise ArgumentError.new("'routing key' cannot be nil") if routing_key.nil?

      @processing_map[routing_key.to_s] = processing_hash_for(filters, processors)
      Rails.logger.info "Registered process mapping for routing key: #{routing_key}"
    end

    def processing_hash_for(filters, processors)
      raise ArgumentError.new("'filters' should be an Array and cannot be nil") if filters.nil? or not filters.is_a? Array
      raise ArgumentError.new("'processors' should be an Array and cannot be nil") if filters.nil? or not processors.is_a? Array
      return {filters: filters, processors: processors}
    end

    def process_data_for(routing_key, payload, opts = {})


      processing_info = @processing_map[routing_key.to_s]
      if processing_info.nil?
        puts "No processing found for routing key: #{routing_key}"
        # Rails.logger.warn "No processing found for routing key: #{routing_key}"
        return
      end
      
      # ::TODO:: Create a new processing class that encapsulates this code
      processed_resources = []
      processing_info[:filters].each do | data_filter |
        data_filter.filter(payload, processed_resources, opts)
      end

      processing_info[:processors].each do | data_processor |
        data_processor.process(payload, processed_resources, opts)
      end
    end

  end
end