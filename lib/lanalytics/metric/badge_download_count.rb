module Lanalytics
  module Metric
    class BadgeDownloadCount < ExpEventsCountElasticMetric
      event_verbs %w(downloaded_open_badge)
    end
  end
end
