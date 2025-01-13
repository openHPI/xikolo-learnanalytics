# frozen_string_literal: true

module Lanalytics
  module Metric
    class VideoStatistics < ExpEventsElasticMetric
      description 'Statistics for videos.'

      optional_parameter :course_id, :item_id

      FORWARD_SEEKS_SCRIPT = <<~SCRIPT
        if (doc['in_context.old_current_time'].size() == 0) return false;
        if (doc['in_context.new_current_time'].size() == 0) return false;
        doc['in_context.old_current_time'].value < doc['in_context.new_current_time'].value
      SCRIPT

      BACKWARD_SEEKS_SCRIPT = <<~SCRIPT
        if (doc['in_context.old_current_time'].size() == 0) return false;
        if (doc['in_context.new_current_time'].size() == 0) return false;
        doc['in_context.old_current_time'].value > doc['in_context.new_current_time'].value
      SCRIPT

      MAX_TIME_SCRIPT = <<~SCRIPT
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

      exec do |params|
        raise ArgumentError.new('course_id or item_id must be provided') unless params[:course_id] || params[:item_id]

        items =
          if params[:item_id]
            [course_api.rel(:item).get(id: params[:item_id]).value!]
          else
            video_items(params[:course_id])
          end

        body = {
          size: 0,
          query: {
            bool: {
              must: [
                {wildcard: {verb: 'video_*'}},
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
                          script: FORWARD_SEEKS_SCRIPT,
                        },
                      },
                    },
                    backward: {
                      filter: {
                        script: {
                          script: BACKWARD_SEEKS_SCRIPT,
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
                        script: MAX_TIME_SCRIPT,
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
          client.search(
            index: datasource.index,
            body:,
            filter_path: %w[
              aggregations.items.buckets.key
              aggregations.items.buckets.plays.user
              aggregations.items.buckets.avg_farthest_watched
              aggregations.items.buckets.seeks.forward
              aggregations.items.buckets.seeks.backward
            ],
          )
        end

        if params[:item_id]
          section = course_api.rel(:section).get(id: items.first['section_id']).value!

          result_data(items.first, [section], result)
        else
          items.map {|i| result_data(i, sections(params[:course_id]), result) }
        end
      end

      class << self
        def item(id, from_result:)
          from_result.dig('aggregations', 'items', 'buckets')&.find do |ri|
            ri['key'] == id
          end
        end

        def result_data(item, sections, result)
          id = item['id']
          ri = item(id, from_result: result)

          section = sections.find {|s| s['id'] == item['section_id'] }

          video_stats = bridge_api.rel(:video_stats).get(video_id: item['content_id']).value!

          {
            id:,
            position: "#{section['position']}.#{item['position']}",
            title: item['title'],
            plays: ri&.dig('plays', 'user', 'value').to_i,
            duration: video_stats['duration'],
            avg_farthest_watched: [
              ri&.dig('avg_farthest_watched', 'value').to_f / video_stats['duration'],
              1.0,
            ].min, # avoid rounding errors over max
            forward_seeks: ri&.dig('seeks', 'forward', 'doc_count').to_i,
            backward_seeks: ri&.dig('seeks', 'backward', 'doc_count').to_i,
          }
        end

        def video_items(course_id)
          videos = []
          Xikolo.paginate(
            course_api.rel(:items).get(
              course_id:,
              content_type: 'video',
            ),
          ) do |video|
            videos.append(video)
          end
          videos
        end

        def sections(course_id)
          sections = []
          Xikolo.paginate(
            course_api.rel(:sections).get(
              course_id:,
              include_alternatives: true,
            ),
          ) do |section|
            sections.append(section)
          end
          sections
        end

        def course_api
          @course_api ||= Restify.new(:course).get.value!
        end

        def bridge_api
          @bridge_api ||= Restify.new(:xikolo).get.value!
        end
      end
    end
  end
end
