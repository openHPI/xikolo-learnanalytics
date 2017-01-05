module Lanalytics
  module Metric
    class ShareButtonClicks < ExpApiMetric

      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        query_must = all_filters(course_id, user_id, nil)

        query_must << [
          { match: { 'verb' => 'share_button_click' } }
        ]

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: query_must
              }
            },
            aggregations: {
              services: {
                terms: {
                  size: 0,
                  field: 'in_context.service'
                }
              }
            }
          }
        end

        return result['aggregations']['services']['buckets'].each_with_object({}) { |service, hash| hash[service['key']] = service['doc_count'] }
      end

    end
  end
end