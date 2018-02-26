module Lanalytics
  module Metric
    class ReferrerCount < ReferrerMetric

      description 'Top 25 referrer with count of given course.'

      required_parameter :course_id

      exec do |params|
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [
                  { match: { 'course_id' => params[:course_id] } }
                ]
              }
            },
            aggregations: {
              referrer: {
                terms: {
                  field: 'referrer',
                  size: 25
                }
              }
            }
          }
        end

        result_set = {}
        result['aggregations']['referrer']['buckets'].each do |item|
          result_set[item['key']] = item['doc_count']
        end
        result_set
      end

    end
  end
end
