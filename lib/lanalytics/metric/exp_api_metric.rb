module Lanalytics
  module Metric
    class ExpApiMetric < Base

      def self.datasource_keys
        %w(exp_api_elastic)
      end

      def self.datasource
        datasources.first
      end

      def self.all_filters(user_id, course_id, resource_id)
        filters_ = course_id.nil? ? [] : [
          { bool: {
              minimum_should_match: 1,
              should: [
                { match: { 'in_context.course_id' => course_id } },
                { match: { 'resource.resource_uuid' => course_id } }
              ]
            }
          }
        ]
        filters_ += user_id.nil? ? [] : [ { match: { 'user.resource_uuid' => user_id } } ]
        filters_ += resource_id.nil? ? [] : [ { match: { 'resource.resource_uuid' => resource_id } } ]
        filters_ + filters
      end

      def self.filters
        []
      end

    end
  end
end
