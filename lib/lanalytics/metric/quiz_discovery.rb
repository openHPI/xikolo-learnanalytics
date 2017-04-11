module Lanalytics
  module Metric
    class QuizDiscovery

      # No support fo start and endtime yet
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        Lanalytics::Clustering::Dimensions.query(course_id, ['quiz_discovery'], [user_id]).first['quiz_discovery'].to_i
      end

    end
  end
end
