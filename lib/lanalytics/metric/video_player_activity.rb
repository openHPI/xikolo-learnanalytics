module Lanalytics
  module Metric
    class VideoPlayerActivity < Base

      description 'The sum of video player-related events (video played, paused, resized, fullscreen triggered, speed changed).'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['video_player_activity'],
          [params[:user_id]]
        ).first['video_player_activity'].to_i
      end

    end
  end
end
