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
                  {
                    match_phrase: {
                      'course_id' => course_id
                    }
                  }
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

        return result['aggregations']['referrer']['buckets'].each_with_object({}) { |item, hash| hash[item['key']] = item['doc_count'] }
      end

    end
  end
end
