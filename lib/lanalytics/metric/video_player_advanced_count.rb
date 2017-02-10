module Lanalytics
  module Metric
    class VideoPlayerAdvancedCount < ExpApiCountMetric

      def self.verbs
        @verbs ||= %w(VIDEO_CHANGE_SIZE VIDEO_CHANGE_SPEED VIDEO_FULLSCREEN)
      end

    end
  end
end
