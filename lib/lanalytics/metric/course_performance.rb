module Lanalytics
  module Metric
    class CoursePerformance
      # No support fo start and endtime yet
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        Lanalytics::Clustering::Dimensions.query(course_id, ['course_performance'], [user_id]).first['course_performance'].to_i
      end

    end
  end
end
