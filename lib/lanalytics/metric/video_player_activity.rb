module Lanalytics
  module Metric
    class VideoPlayerActivity < ClusteringMetric
      description 'The sum of video player-related events (video played, paused, resized, fullscreen triggered, speed changed).'

      dimension_name 'video_player_activity'
    end
  end
end
