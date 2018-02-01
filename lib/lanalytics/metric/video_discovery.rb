module Lanalytics
  module Metric
    class VideoDiscovery < Base

      description 'The number of visited videos relative to the available ones.'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['video_discovery'],
          [params[:user_id]]
        ).first['video_discovery'].to_i
      end

    end
  end
end
