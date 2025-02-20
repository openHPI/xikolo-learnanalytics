# frozen_string_literal: true

module Lanalytics
  module Metric
    class VideoPlayerActivity < ClusteringMetric
      description <<~DOC
        The sum of video player-related events (video played, paused, resized, fullscreen triggered, speed changed).
      DOC

      dimension_name 'video_player_activity'
    end
  end
end
