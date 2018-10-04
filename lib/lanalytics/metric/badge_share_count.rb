module Lanalytics
  module Metric
    class BadgeShareCount < ExpApiCountMetric

      event_verbs %w(share_open_badge)

    end
  end
end
