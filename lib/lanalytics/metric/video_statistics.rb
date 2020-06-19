# frozen_string_literal: true

module Lanalytics
  module Metric
    class VideoStatistics < ExpEventsElasticMetric
      description 'Statistics for videos.'

      optional_parameter :course_id, :item_id

      exec do |params|
        unless params[:course_id] || params[:item_id]
          raise ArgumentError.new('course_id or item_id must be provided')
        end

        forward_seeks_script = <<~SCRIPT
          if (doc['in_context.old_current_time'].size() == 0) return false;
          if (doc['in_context.new_current_time'].size() == 0) return false;
          doc['in_context.old_current_time'].value < doc['in_context.new_current_time'].value
        SCRIPT

        backward_seeks_script = <<~SCRIPT
          if (doc['in_context.old_current_time'].size() == 0) return false;
          if (doc['in_context.new_current_time'].size() == 0) return false;
          doc['in_context.old_current_time'].value > doc['in_context.new_current_time'].value
        SCRIPT

        max_time_script = <<~SCRIPT
          float current_time;
          float new_current_time;
          float old_current_time;

          if (doc['in_context.current_time'].size() != 0) {
              current_time = (float) doc['in_context.current_time'].value;
          }
          if (doc['in_context.new_current_time'].size() != 0) {
              new_current_time = (float) doc['in_context.new_current_time'].value;
          }
          if (doc['in_context.old_current_time'].size() != 0) {
              old_current_time = (float) doc['in_context.old_current_time'].value;
          }

          Math.max(
            current_time,
            Math.max(
              new_current_time,
              old_current_time
            )
          );
        SCRIPT

        body = {
          size: 0,
          query: {
            bool: {
              must: [
                {wildcard: {verb: 'video_*'}},
              ].append(
                course_filter(params[:course_id]),
                resource_filter(params[:item_id]),
              ).compact,
            },
          },
          aggs: {
            items: {
              terms: {
                field: 'resource.resource_uuid',
                size: 1_000,
              },
              aggs: {
                plays: {
                  filter: {
                    bool: {
                      must: [
                        {match: {verb: 'video_play'}},
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
                },
                seeks: {
                  filter: {
                    bool: {
                      must: [
                        {wildcard: {verb: 'video*seek'}},
                      ],
                    },
                  },
                  aggs: {
                    forward: {
                      filter: {
                        script: {
                          script: forward_seeks_script,
                        },
                      },
                    },
                    backward: {
                      filter: {
                        script: {
                          script: backward_seeks_script,
                        },
                      },
                    },
                  },
                },
                farthest_watched: {
                  terms: {
                    field: 'user.resource_uuid',
                  },
                  aggs: {
                    max_time: {
                      max: {
                        script: max_time_script,
                      },
                    },
                  },
                },
                avg_farthest_watched: {
                  avg_bucket: {
                    buckets_path: 'farthest_watched>max_time',
                  },
                },
              },
            },
          },
        }

        result = datasource.exec do |client|
          client.search index: datasource.index,
                        body: body,
                        filter_path: %w[
                          aggregations.items.buckets.key
                          aggregations.items.buckets.plays.user
                          aggregations.items.buckets.avg_farthest_watched
                          aggregations.items.buckets.seeks.forward
                          aggregations.items.buckets.seeks.backward
                        ]
        end

        course_api = Xikolo.api(:course).value!

        sections = []

        if params[:item_id]
          item = Xikolo.api(:course).value!
            .rel(:item).get(id: params[:item_id]).value!

          sections.append(
            course_api.rel(:section).get(id: item['section_id']).value!,
          )

          result_data(item, sections, result)
        else
          Xikolo.paginate(
            course_api.rel(:sections).get(course_id: params[:course_id]),
          ) do |section|
            sections.append(section)
          end

          video_items(params[:course_id]).map do |i|
            result_data(i, sections, result)
          end
        end
      end

      def self.item(id, from_result:)
        from_result.dig('aggregations', 'items', 'buckets')&.find do |ri|
          ri['key'] == id
        end
      end

      def self.result_data(item, sections, result)
        id = item['id']
        ri = item(id, from_result: result)

        section = sections.find {|s| s['id'] == item['section_id'] }

        video = Xikolo.api(:video).value!
          .rel(:video).get(id: item['content_id']).value!

        {
          id: id,
          position: "#{section['position']}.#{item['position']}",
          title: item['title'],
          plays: ri&.dig('plays', 'user', 'value').to_i,
          duration: video['duration'],
          avg_farthest_watched: [
            ri&.dig('avg_farthest_watched', 'value').to_f / video['duration'],
            1.0,
          ].min, # avoid rounding errors over max
          forward_seeks: ri&.dig('seeks', 'forward', 'doc_count').to_i,
          backward_seeks: ri&.dig('seeks', 'backward', 'doc_count').to_i,
        }
      end

      def self.video_items(course_id)
        videos = []
        Xikolo.paginate(
          Xikolo.api(:course).value!.rel(:items).get(
            course_id: course_id,
            content_type: 'video',
          ),
        ) do |video|
          videos.append(video)
        end
        videos
      end
    end
  end
end
