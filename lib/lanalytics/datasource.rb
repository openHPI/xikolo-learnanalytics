module Lanalytics
  class Datasource
    attr_reader :type, :url

    def initialize(type, url, filters = [], processors = [])
      
      @type ||= type
      @url ||= url
      
      filters ||= []
      @filters = filters

      processors ||= []
      @processors = processors
    end

    def process(original_resource_as_hash)
      processed_resource = []
      
      @filters.each do | data_filter |
        filter_result = data_filter.filter(self, original_resource_as_hash, processed_resource)

        if filter_result.is_a? Array
          processed_resource += filter_result
        else 
          processed_resource += [filter_result]
        end
      end

      @processors.each do | data_processor |
        data_processor.process(original_resource_as_hash, processed_resource)
      end
    end

  end
end