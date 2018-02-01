module Lanalytics
  module Metric
    class DownloadActivity < Base

      description 'The sum of download-related events.'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['download_activity'],
          [params[:user_id]]
        ).first['download_activity'].to_i
      end

    end
  end
end
