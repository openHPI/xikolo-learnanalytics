# frozen_string_literal: true

module Lanalytics
  module Metric
    class LinkTrackingEventsElasticMetric < Base
      def self.datasource_keys
        %w[link_tracking_events_elastic]
      end

      def self.datasource
        datasources.first
      end
    end
  end
end
