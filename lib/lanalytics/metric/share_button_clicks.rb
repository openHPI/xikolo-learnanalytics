module Lanalytics
  module Metric
    class ShareButtonClicks < ExpApiMetric

      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        result = datasource.exec do |client|
          query_must = all_filters(user_id, course_id, nil)

          query_must << [
            { match: { 'verb' => 'share_button_click' } }
          ]

          query = {
            size: 0,
            query: {
              bool: {
                must: query_must
              }
            },
            aggregations: {
              services: {
                terms: {
                  field: 'in_context.service',
                  size: 25
                }
              }
            }
          }

          if start_time.present? and end_time.present?
            query[:query][:bool][:filter] = {
              range: {
                timestamp: {
                  gte: DateTime.parse(start_time).iso8601,
                  lte: DateTime.parse(end_time).iso8601
                }
              }
            }
          end

          client.search index: datasource.index, body: query
        end

        return result['aggregations']['services']['buckets'].each_with_object({}) { |service, hash| hash[service['key']] = service['doc_count'] }
      end

    end
  end
end