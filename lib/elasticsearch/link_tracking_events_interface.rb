# frozen_string_literal: true

module Elasticsearch
  # interface for interacting with elasticsearch, also used by integration
  class LinkTrackingEventsInterface
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
      ActiveSupport::JSON.decode Rails.root.join('config/elasticsearch/link_tracking_events.json').read
    end

    def self.datasource
      Lanalytics::Processing::DatasourceManager.datasource(
        'link_tracking_events_elastic',
      )
    end
  end
end
