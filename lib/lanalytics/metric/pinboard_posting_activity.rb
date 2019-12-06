module Lanalytics
  module Metric
    class PinboardPostingActivity < ExpEventsCountElasticMetric

      event_verbs %w(ASKED_QUESTION ANSWERED_QUESTION COMMENTED)

    end
  end
end
