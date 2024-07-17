# frozen_string_literal: true

module Lanalytics
  module Metric
    class RichTextLinks < LinkTrackingEventsElasticMetric
      description 'Stats for all links of a rich text item.'

      required_parameter :item_id

      exec do |params|
        body = {
          size: 0,
          query: {
            bool: {
              must: [
                {match: {tracking_type: 'rich_text_item_link'}},
                {match: {tracking_id: params[:item_id]}},
              ],
            },
          },
          aggs: {
            links: {
              terms: {
                field: 'tracking_external_link',
                size: 10_000,
              },
              aggs: {
                user: {
                  cardinality: {
                    field: 'user_id',
                    precision_threshold: 40_000,
                  },
                },
                earliest_timestamp: {
                  top_hits: {
                    sort: [
                      {timestamp: {order: 'asc'}},
                    ],
                    _source: ['timestamp'],
                    size: 1,
                  },
                },
                latest_timestamp: {
                  top_hits: {
                    sort: [
                      {timestamp: {order: 'desc'}},
                    ],
                    _source: ['timestamp'],
                    size: 1,
                  },
                },
              },
            },
          },
        }

        result = datasource.exec do |client|
          client.search(index: datasource.index, body:)
        end

        result.dig('aggregations', 'links', 'buckets').map do |item|
          {
            link: item['key'],
            total_clicks: item['doc_count'].to_i,
            total_clicks_unique_users: item.dig('user', 'value').to_i,
            earliest_timestamp: item.dig('earliest_timestamp', 'hits', 'hits', 0, '_source', 'timestamp'),
            latest_timestamp: item.dig('latest_timestamp', 'hits', 'hits', 0, '_source', 'timestamp'),
          }
        end
      end
    end
  end
end
