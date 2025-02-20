# frozen_string_literal: true

module Lanalytics
  module Metric
    class ItemDiscovery < ClusteringMetric
      description <<~DOC
        The number of visited items relative to the available ones. Visited means a single click on the item.
      DOC

      dimension_name 'item_discovery'
    end
  end
end
