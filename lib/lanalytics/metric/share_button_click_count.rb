module Lanalytics
  module Metric
    class  ShareButtonClickCount < ExpApiCountMetric

      event_verbs %w(SHARE_BUTTON_CLICK SHARE_COURSE)

    end
  end
end
