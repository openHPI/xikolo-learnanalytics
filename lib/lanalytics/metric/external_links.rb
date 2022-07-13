module Lanalytics
  module Metric
    class ExternalLinks < LinkTrackingEventsElasticMetric
      description 'Counts the total and unique clicks for a given announcement tracking id.'

      required_parameter :tracking_id

      exec do |params|
        # uuid is probably base62 encoded, also in elastic
        tracking_id = UUID4.try_convert(params[:tracking_id])
        next {} unless tracking_id

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [
                  {match: {'tracking_type' => 'news'}},
                  {exists: {'field' => 'tracking_external_link'}},
                  {bool: {
                    minimum_should_match: 1,
                    should: [
                      {match: {'tracking_id' => tracking_id.to_s(format: :default)}},
                      {match: {'tracking_id' => tracking_id.to_s(format: :base62)}}
                    ]
                  }}
                ]
              }
            },
            aggregations: {
              external_links: {
                terms: {
                  field: 'tracking_external_link',
                  size: 100
                },
                aggregations: {
                  unique_users: {
                    cardinality: {
                      field: 'user_id'
                    }
                  }
                }
              }
            }
          }
        end

        result['aggregations']['external_links']['buckets'].each_with_object({}) do |link, hash|
          hash[link['key']] = {
            total_clicks: link['doc_count'],
            unique_clicks: link['unique_users']['value']
          }
        end
      end
    end
  end
end
