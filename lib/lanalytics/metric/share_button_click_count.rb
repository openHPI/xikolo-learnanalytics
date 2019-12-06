# frozen_string_literal: true

module Lanalytics
  module Metric
    class ShareButtonClickCount < ExpEventsCountElasticMetric
      event_verbs %w[SHARE_BUTTON_CLICK SHARE_COURSE]
    end
  end
end
