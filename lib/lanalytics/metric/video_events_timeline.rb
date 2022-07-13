# frozen_string_literal: true

module Lanalytics
  module Metric
    class VideoEventsTimeline < ExpEventsElasticMetric
      description 'Counts per video event type.'

      required_parameter :item_id

      exec do |params|
        verbs = %w[play pause change_speed seek]

        verbs_filter = {
          bool: {
            minimum_should_match: 1,
            should: [],
          },
        }

        verbs.each do |verb|
          verbs_filter.dig(:bool, :should) <<
            {match: {verb: "video_#{verb}"}}
        end

        body = {
          size: 0,
          query: {
            bool: {
              must: [verbs_filter] + all_filters(
                nil,
                nil,
                params[:item_id],
              ),
              must_not: {
                term: {'in_context.current_time' => '0'},
              },
            },
          },
          aggs: {
            timestamps: {
              histogram: {
                field: 'in_context.current_time',
                interval: '10',
                min_doc_count: '0',
              },
              aggs: {
                verbs: {
                  terms: {
                    field: 'verb',
                  },
                },
              },
            },
            old_timestamps: {
              histogram: {
                field: 'in_context.old_current_time',
                interval: '10',
                min_doc_count: '0',
              },
              aggs: {
                verbs: {
                  terms: {
                    field: 'verb',
                  },
                },
              },
            },
          },
        }

        result = datasource.exec do |client|
          client.search index: datasource.index, body: body
        end

        values = result.dig('aggregations', 'timestamps', 'buckets').map do |r|
          e = {time: r['key']}

          verbs.each do |verb|
            e[verb] = r
              .dig('verbs', 'buckets')
              .find {|i| i['key'] == "video_#{verb}" }
              &.dig('doc_count').to_i
          end

          e
        end

        # workaround for seek events
        result.dig('aggregations', 'old_timestamps', 'buckets').each do |r|
          e = values.find {|v| v[:time] == r['key'] }

          e['seek_start'] = r
            .dig('verbs', 'buckets')
            .find {|i| i['key'] == 'video_seek' }
            &.dig('doc_count').to_i
        end

        values
      end
    end
  end
end
