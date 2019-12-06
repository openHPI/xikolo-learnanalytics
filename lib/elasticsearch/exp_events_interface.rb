# frozen_string_literal: true

module Elasticsearch
  # interface for interacting with elasticsearch, also used by integration
  class ExpEventsInterface
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
      ActiveSupport::JSON.decode File.read(
        "#{Rails.root}/config/elasticsearch/exp_events.json",
      )
    end

    def self.datasource
      Lanalytics::Processing::DatasourceManager.datasource(
        'exp_events_elastic',
      )
    end
  end
end
