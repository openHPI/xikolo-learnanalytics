module Lanalytics
  module Metric
    class DownloadActivity
      # No support fo start and endtime yet
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        Lanalytics::Clustering::Dimensions.query(course_id, ['download_activity'], [user_id]).first['download_activity'].to_i
      end

    end
  end
end
