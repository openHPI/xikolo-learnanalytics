# frozen_string_literal: true

module Lanalytics
  module Metric
    class ItemDiscovery < ClusteringMetric
      description 'The number of visited items relative to the available ones. Visited means a single click on the item.'

      dimension_name 'item_discovery'
    end
  end
end
