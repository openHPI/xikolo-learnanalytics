module Lanalytics
  module Metric
    class ReferrerMetric
      def self.datasource
        Lanalytics::Processing::DatasourceManager.datasource(datasource_name)
      end

      def self.datasource_name
        'referral'
      end

      def self.all_filters(course_id = nil, user_id = nil, ressource_id = nil)
        filters_ = course_id.nil? ? [] : [{match_phrase: {'in_context.course_id' => course_id}}]
        filters_ += user_id.nil? ? [] : [{match_phrase: {'user.resource_uuid' => user_id}}]
        filters_ += ressource_id.nil? ? [] : [{match_phrase: {'resource.resource_uuid' => ressource_id}}]
        filters_ + filters
      end

      def self.filters
        []
      end
    end
  end
end