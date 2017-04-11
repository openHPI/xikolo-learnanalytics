module Lanalytics
  module Metric
    class ItemDiscovery

      # No support fo start and endtime yet
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        Lanalytics::Clustering::Dimensions.query(course_id, ['item_discovery'], [user_id]).first['item_discovery'].to_i
      end

    end
  end
end
