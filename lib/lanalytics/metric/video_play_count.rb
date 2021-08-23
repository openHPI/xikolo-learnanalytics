# frozen_string_literal: true

module Lanalytics
  module Metric
    class VideoPlayCount < ExpEventsElasticMetric
      description 'Videos played by users.'

      required_parameter :course_id

      exec do |params|
        items = video_items(params[:course_id])

        body = {
          size: 0,
          query: {
            bool: {
              must: [
                {match: {verb: 'video_play'}},
              ].append(resources_filter(items.pluck('id'))).compact,
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

      class << self
        private

        def video_items(course_id)
          videos = []
          Xikolo.paginate(
            course_api.rel(:items).get(
              course_id: course_id,
              content_type: 'video',
            ),
          ) do |video|
            videos.append(video)
          end
          videos
        end

        def course_api
          @course_api ||= Restify.new(:course).get.value!
        end
      end
    end
  end
end
