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
      processed_resources = []
      
      opts = {
        import_action: Lanalytics::Processor::ProcessingAction::CREATE,
        data_source: self
      }
      
      @filters.each do | data_filter |
        filter_result = data_filter.filter(original_resource_as_hash, processed_resources, opts)
      end

      @processors.each do | data_processor |
        data_processor.process(original_resource_as_hash, processed_resources, opts)
      end
    end

  end
end

# class Lanalytics::DataImporter
#   def import()
#   end
# end