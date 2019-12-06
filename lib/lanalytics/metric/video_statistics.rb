# frozen_string_literal: true

module Lanalytics
  module Metric
    # rubocop:disable Metrics/ClassLength
    class VideoStatistics < ExpEventsElasticMetric

      description 'Statistics for all videos of a course.'

      required_parameter :course_id

      optional_parameter :item_id

      # rubocop:disable Metrics/LineLength
      exec do |params|
        body = {
          size: 0,
          query: {
            bool: {
              must: [
                {
                  bool: {
                    minimum_should_match: 1,
                    should: [
                      {wildcard: {verb: 'video_*'}},
                      {match: {verb: 'visited_item'}},
                    ],
                  },
                },
              ] + all_filters(nil, params[:course_id], params[:item_id]),
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
                visits: {
                  filter: {
                    bool: {
                      must: [
                        {match: {verb: 'visited_item'}},
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
                          script: "
                            if (doc['in_context.old_current_time'].size() == 0) return false;
                            if (doc['in_context.new_current_time'].size() == 0) return false;
                            doc['in_context.old_current_time'].value < doc['in_context.new_current_time'].value
                          ",
                        },
                      },
                    },
                    backward: {
                      filter: {
                        script: {
                          script: "
                            if (doc['in_context.old_current_time'].size() == 0) return false;
                            if (doc['in_context.new_current_time'].size() == 0) return false;
                            doc['in_context.old_current_time'].value > doc['in_context.new_current_time'].value
                          ",
                        },
                      },
                    },
                  },
                },
                farthest_watched: {
                  filter: {
                    bool: {
                      must: [
                        {wildcard: {verb: 'video_*'}},
                      ],
                    },
                  },
                  aggs: {
                    user: {
                      terms: {
                        field: 'user.resource_uuid',
                        size: 100_000,
                      },
                      aggs: {
                        max_time: {
                          max: {
                            script: "
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
                            ",
                          },
                        },
                      },
                    },
                    avg: {
                      avg_bucket: {
                        buckets_path: 'user>max_time',
                      },
                    },
                  },
                },
              },
            },
          },
        }
        # rubocop:enable Metrics/LineLength

        result = datasource.exec do |client|
          client.search index: datasource.index, body: body,
                        filter_path: %w[
                          aggregations.items.buckets.key
                          aggregations.items.buckets.plays.user
                          aggregations.items.buckets.visits.user
                          aggregations.items.buckets.farthest_watched.avg
                          aggregations.items.buckets.seeks.forward
                          aggregations.items.buckets.seeks.backward
                        ]
        end

        course_api = Xikolo.api(:course).value!

        sections = []
        Xikolo.paginate(
          course_api.rel(:sections).get(course_id: params[:course_id]),
        ) do |section|
          sections << section
        end

        if params[:item_id]
          item = Xikolo.api(:course).value!
            .rel(:item).get(id: params[:item_id]).value!
          result_data(item, sections, result)
        else
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
          visits: ri&.dig('visits', 'user', 'value').to_i,
          avg_farthest_watched: ri&.dig('farthest_watched', 'avg', 'value')
            .to_f / video['duration'],
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
    # rubocop:enable all
  end
end
