# frozen_string_literal: true

module Lanalytics
  module Metric
    class DownloadActivity < ClusteringMetric
      description 'The sum of download-related events.'

      dimension_name 'download_activity'
    end
  end
end
