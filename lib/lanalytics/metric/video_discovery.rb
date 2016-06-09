module Lanalytics
  module Metric
    class VideoDiscovery
      # No support fo start and endtime yet
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        Lanalytics::Clustering::Dimensions.query(course_id, ['video_discovery'], [user_id]).first['video_discovery'].to_i
      end

    end
  end
end
