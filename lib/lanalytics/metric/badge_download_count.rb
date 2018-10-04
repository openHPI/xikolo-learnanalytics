module Lanalytics
  module Metric
    class BadgeDownloadCount < ExpApiCountMetric

      event_verbs %w(downloaded_open_badge)

    end
  end
end
