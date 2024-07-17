# frozen_string_literal: true

module Lanalytics
  module Metric
    class DownloadCount < ExpEventsElasticMetric
      description 'Counts all downloads for all video items of a course.'

      required_parameter :course_id

      exec do |params|
        video_items = video_items(params[:course_id])

        verbs = %w[
          hd_video
          sd_video
          hls_video
          slides
          audio
          transcript
        ]

        body = {
          size: 0,
          query: {
            bool: {
              must: all_filters(nil, params[:course_id], nil) + download_verbs_filter(verbs),
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
          },
        }

        verbs.each do |verb|
          body.dig(:aggs, :items, :aggs)[verb] = {
            filter: {
              bool: {
                must: [
                  {match: {verb: "downloaded_#{verb}"}},
                ],
              },
            },
            aggs: {
              user: {
                cardinality: {
                  field: 'user.resource_uuid',
                  precision_threshold: 40_000,
                },
              },
            },
          }
        end

        result = datasource.exec do |client|
          client.search(index: datasource.index, body:)
        end

        course_api = Restify.new(:course).get.value!

        sections = []
        Xikolo.paginate(
          course_api.rel(:sections).get(
            course_id: params[:course_id],
            include_alternatives: true,
          ),
        ) do |section|
          sections << section
        end

        video_items.map do |item|
          id = item['id']
          ri = item(id, from_result: result)

          section = sections.find {|s| s['id'] == item['section_id'] }

          stats = {
            id:,
            position: "#{section['position']}.#{item['position']}",
            title: item['title'],
            total_downloads: ri&.dig('doc_count').to_i,
            total_downloads_unique_users: ri&.dig('user', 'value').to_i,
          }

          verbs.each do |verb|
            stats.merge!(
              "#{verb}_downloads" => ri&.dig(verb, 'doc_count').to_i,
              "#{verb}_downloads_unique_users" => ri&.dig(verb, 'user', 'value').to_i,
            )
          end

          stats
        end
      end

      def self.item(id, from_result:)
        from_result.dig('aggregations', 'items', 'buckets')&.find do |ri|
          ri['key'] == id
        end
      end

      def self.video_items(course_id)
        videos = []
        Xikolo.paginate(
          Restify.new(:course).get.value!.rel(:items).get(
            course_id:,
            content_type: 'video',
          ),
        ) do |video|
          videos.append(video)
        end
        videos
      end

      def self.download_verbs_filter(verbs)
        filter = [{bool: {should: []}}]
        verbs.each do |verb|
          filter[0][:bool][:should] << {match: {verb: "downloaded_#{verb}"}}
        end
        filter
      end
    end
  end
end
