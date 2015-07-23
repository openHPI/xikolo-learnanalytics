module Lanalytics
  module Metric
    class ExpApiMetric
      def self.datasource
        Lanalytics::Processing::DatasourceManager.get_datasource(datasource_name)
      end

      def self.datasource_name
        'exp_api_elastic'
      end

      def self.all_filters(course_id=nil, user_id=nil)
        filters_ = if course_id.nil?
                     []
                   else
                     [{match_phrase: {'in_context.course_id' => course_id}}]
                   end
        filters_ += if user_id.nil?
                     []
                   else
                     [{match_phrase: {'user.resource_uuid' => user_id}}]
                   end
        filters_ + filters
      end

      def self.filters
        []
      end
    end
  end
end
