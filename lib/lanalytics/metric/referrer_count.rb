module Lanalytics
  module Metric
    class ReferrerCount < ReferrerMetric
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
              size: 0,
              query: {
                bool: {
                  must: [
                    { match: { 'course_id' => course_id } }
                  ]
                }
              },
              aggregations: {
                referrer: {
                  terms: {
                    field: 'referrer',
                    size: 0
                  }
                }
              }
          }

        end
        result_set = {}
        result['aggregations']['referrer']['buckets'].each do |item|
          result_set[item['key']] = item['doc_count']
        end
        return result_set
        end
      end
    end
  end