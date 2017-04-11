module Lanalytics
  module Metric
    class MainQuizPerformance

      # No support fo start and endtime yet
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        Lanalytics::Clustering::Dimensions.query(course_id, ['main_quiz_performance'], [user_id]).first['main_quiz_performance'].to_i
      end

    end
  end
end
