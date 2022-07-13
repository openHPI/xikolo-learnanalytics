module Lanalytics
  module Metric
    class TopItems < ExpEventsElasticMetric
      description 'Returns all course items with visits.'

      required_parameter :course_id

      exec do |params|
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [
                  match: {verb: 'visited_item'}
                ] + all_filters(nil, params[:course_id], nil)
              }
            },
            aggregations: {
              items: {
                terms: {
                  field: 'resource.resource_uuid',
                  size: 1000
                },
                aggregations: {
                  user: {
                    cardinality: {
                      field: 'user.resource_uuid'
                    }
                  }
                }
              }
            }
          }
        end

        result.dig('aggregations', 'items', 'buckets')&.map do |bucket|
          {
            item_id: bucket['key'],
            visits: bucket['doc_count'],
            user: bucket.dig('user', 'value')
          }
        end
      end
    end
  end
end
