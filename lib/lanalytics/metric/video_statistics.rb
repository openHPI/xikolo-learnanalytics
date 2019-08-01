module Lanalytics
  module Metric
    class VideoStatistics < ExpApiMetric

      description 'Statistics for all videos of a course.'

      required_parameter :course_id

      exec do |params|
        video_items = video_items(params[:course_id])

        body = {
          size: 0,
          query: {
            bool: {
              must: [
                {
                  bool: {
                    minimum_should_match: 1,
                    should: [
                      { wildcard: { verb: 'video_*' } },
                      { match: { verb: 'visited_item' } }
                    ]
                  }
                }
              ] + all_filters(nil, params[:course_id], nil)
            }
          },
          aggs: {
            items: {
              terms: {
                field: 'resource.resource_uuid',
                size: 1_000
              },
              aggs: {
                plays: {
                  filter: {
                    bool: {
                      must: [
                        { match: { verb: 'video_play' } }
                      ]
                    }
                  },
                  aggs: {
                    user: {
                      cardinality: {
                        field: 'user.resource_uuid',
                        precision_threshold: 40_000
                      }
                    }
                  }
                },
                visits: {
                  filter: {
                    bool: {
                      must: [
                        { match: { verb: 'visited_item' } }
                      ]
                    }
                  },
                  aggs: {
                    user: {
                      cardinality: {
                        field: 'user.resource_uuid',
                        precision_threshold: 40_000
                      }
                    }
                  }
                },
                seeks: {
                  filter: {
                    bool: {
                      must: [
                        { wildcard: { verb: 'video*seek' } }
                      ]
                    }
                  },
                  aggs: {
                    forward: {
                      filter: {
                        script: {
                          script: "doc['in_context.old_current_time'].value < doc['in_context.new_current_time'].value"
                        }
                      }
                    },
                    backward: {
                      filter: {
                        script: {
                          script: "doc['in_context.old_current_time'].value > doc['in_context.new_current_time'].value"
                        }
                      }
                    }
                  }
                },
                farthest_watched: {
                  filter: {
                    bool: {
                      must: [
                        { wildcard: { verb: 'video_*' } }
                      ]
                    }
                  },
                  aggs: {
                    user: {
                      terms: {
                        field: 'user.resource_uuid',
                        size: 100_000
                      },
                      aggs: {
                        max_time: {
                          max: {
                            script: "
                              Math.max(
                                doc['in_context.current_time'].value,
                                Math.max(
                                  doc['in_context.new_current_time'].value,
                                  doc['in_context.old_current_time'].value
                                )
                              )
                            "
                          }
                        }
                      }
                    },
                    avg: {
                      avg_bucket: {
                        buckets_path: 'user>max_time'
                      }
                    }
                  }
                }
              }
            }
          }
        }

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
        video_api = Xikolo.api(:video).value!

        sections = []
        Xikolo.paginate(
          course_api.rel(:sections).get(course_id: params[:course_id])
        ) do |section|
          sections << section
        end

        video_items.map do |item|
          id = item['id']
          ri = item(id, from_result: result)

          section = sections.find {|section| section['id'] == item['section_id'] }

          video = video_api.rel(:video).get(id: item['content_id']).value!

          {
            id: id,
            position: "#{section['position']}.#{item['position']}",
            title: item['title'],
            plays: ri&.dig('plays', 'user', 'value').to_i,
            visits: ri&.dig('visits', 'user', 'value').to_i,
            avg_farthest_watched: ri&.dig('farthest_watched', 'avg', 'value').to_f / video['duration'],
            forward_seeks: ri&.dig('seeks', 'forward', 'doc_count').to_i,
            backward_seeks: ri&.dig('seeks', 'backward', 'doc_count').to_i
          }
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
          Xikolo.api(:course).value!.rel(:items).get(
            course_id: course_id,
            content_type: 'video'
          )
        ) do |video|
          videos.append(video)
        end
        videos
      end

    end
  end
end
