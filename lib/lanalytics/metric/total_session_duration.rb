module Lanalytics
  module Metric
    class TotalSessionDuration
      # No support fo start and endtime yet
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        Lanalytics::Clustering::Dimensions.query(course_id, ['total_session_duration'], [user_id]).first['total_session_duration'].to_i
      end

    end
  end
end
