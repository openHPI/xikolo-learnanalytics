module Lanalytics
  module Metric
    class VideoSpeedChangeMetric < ExpEventsCountElasticMetric

      event_verbs %w(VIDEO_CHANGE_SPEED)

    end
  end
end
