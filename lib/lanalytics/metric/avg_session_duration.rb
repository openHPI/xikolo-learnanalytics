module Lanalytics
  module Metric
    class AvgSessionDuration
      # No support fo start and endtime yet
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        Lanalytics::Clustering::Dimensions.query(course_id, ['average_session_duration'], [user_id]).first['average_session_duration'].to_i
      end

    end
  end
end
