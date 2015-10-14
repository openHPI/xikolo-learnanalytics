module Lanalytics
  module Metric
    class ExpApiMetric
      def self.datasource
        Lanalytics::Processing::DatasourceManager.datasource(datasource_name)
      end

      def self.datasource_name
        'exp_api_elastic'
      end

      def self.all_filters(course_id = nil, user_id = nil)
        filters_ = course_id.nil? ? [] : [{match_phrase: {'in_context.course_id' => course_id}}]
        filters_ += user_id.nil? ? [] : [{match_phrase: {'user.resource_uuid' => user_id}}]
        filters_ + filters
      end

      def self.filters
        []
      end
    end
  end
end
