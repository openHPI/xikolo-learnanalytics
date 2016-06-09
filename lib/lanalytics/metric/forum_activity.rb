module Lanalytics
  module Metric
    class ForumActivity
      # No support fo start and endtime yet
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        Lanalytics::Clustering::Dimensions.query(course_id, ['forum_activity'], [user_id]).first['forum_activity'].to_i
      end

    end
  end
end
