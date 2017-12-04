module Lanalytics
  module Metric
    class LastVisitedItem < ExpApiMetric

      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 1,
            query: {
              bool: {
                must: [
                  { match: { 'verb' => 'visited_item' } }
                ] + all_filters(user_id, course_id, nil),
              }
            },
            sort: {
              timestamp: {
                order: 'desc'
              }
            }
          }
        end
        result.dig('hits', 'hits', 0, '_source') || {}
      end

    end
  end
end
