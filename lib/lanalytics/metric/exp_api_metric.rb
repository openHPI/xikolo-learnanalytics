module Lanalytics
  module Metric
    class ExpApiMetric
      def self.datasource
        Lanalytics::Processing::DatasourceManager.datasource(datasource_name)
      end

      def self.datasource_name
        'exp_api_elastic'
      end

      def self.all_filters(course_id = nil, user_id = nil, ressource_id = nil)
        filters_ = course_id.nil? ? [] : [
          { bool: {
              should: [
                { match: { 'in_context.course_id' => course_id } },
                { match: { 'resource.resource_uuid' => course_id } }
              ]
            }
          }
        ]
        filters_ += user_id.nil? ? [] : [ { match: { 'user.resource_uuid' => user_id } } ]
        filters_ += ressource_id.nil? ? [] : [ { match: { 'resource.resource_uuid' => ressource_id } } ]
        filters_ + filters
      end

      def self.filters
        []
      end
    end
  end
end
