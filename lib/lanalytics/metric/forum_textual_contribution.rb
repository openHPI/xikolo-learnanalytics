module Lanalytics
  module Metric
    class ForumTextualContribution

      # No support fo start and endtime yet
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        Lanalytics::Clustering::Dimensions.query(course_id, ['textual_forum_contribution'], [user_id]).first['textual_forum_contribution'].to_i
      end

    end
  end
end
