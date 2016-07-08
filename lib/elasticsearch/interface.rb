module Elasticsearch

  # interface for interacting with elasticsearch, also used by integration
  class Interface

    # elasticsearch client
    def self.client
      datasource.client
    end

    # elasticsearch index
    def self.index
      datasource.index
    end

    # elasticsearch mapping
    def self.mapping
      ActiveSupport::JSON.decode File.read("#{Rails.root}/config/elasticsearch/mapping.json")
    end

    private

    def self.datasource
      Lanalytics::Processing::DatasourceManager.datasource('exp_api_elastic')
    end

  end

end