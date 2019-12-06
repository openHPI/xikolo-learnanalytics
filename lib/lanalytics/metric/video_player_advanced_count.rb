module Lanalytics
  module Metric
    class VideoPlayerAdvancedCount < ExpEventsCountElasticMetric

      event_verbs %w(VIDEO_CHANGE_SIZE VIDEO_CHANGE_SPEED VIDEO_FULLSCREEN)

    end
  end
end
