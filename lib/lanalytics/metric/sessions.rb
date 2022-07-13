# frozen_string_literal: true

module Lanalytics
  module Metric
    class Sessions < ClusteringMetric
      description 'The number of consecutive event streams where individual events have no wider gap than 30 minutes.'

      dimension_name 'sessions'
    end
  end
end
