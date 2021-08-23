# frozen_string_literal: true

module Lanalytics
  module Metric
    class VideoPlayCount < ExpEventsElasticMetric
      description 'Videos played by users.'

      required_parameter :course_id

      exec do |params|
        body = {
          size: 0,
          query: {
            bool: {
              must: [
                {match: {verb: 'video_play'}},
              ] + all_filters(nil, params[:course_id], nil),
            },
          },
          aggs: {
            items: {
              terms: {
                field: 'resource.resource_uuid',
                size: 1_000,
              },
              aggs: {
                user: {
                  cardinality: {
                    field: 'user.resource_uuid',
                    precision_threshold: 40_000,
                  },
                },
              },
            },
            sum: {
              sum_bucket: {
                buckets_path: 'items>user',
              },
            },
          },
        }

        result = datasource.exec do |client|
          client.search index: datasource.index, body: body
        end

        {count: result.dig('aggregations', 'sum', 'value').to_i}
      end
    end
  end
end
