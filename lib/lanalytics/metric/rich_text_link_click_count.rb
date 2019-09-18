module Lanalytics
  module Metric
    class RichTextLinkClickCount < ExpApiMetric

      description 'Counts all link clicks for all rich text items of a course.'

      required_parameter :course_id

      exec do |params|
        rich_text_items = rich_text_items(params[:course_id])

        body = {
          size: 0,
          query: {
            bool: {
              must: [
                { match: { tracking_type: 'rich_text_item_link' } },
                { match: { course_id: params[:course_id] } }
              ]
            }
          },
          aggs: {
            items: {
              terms: {
                field: 'tracking_id',
                size: 1_000
              },
              aggs: {
                user: {
                  cardinality: {
                    field: 'user_id',
                    precision_threshold: 40_000
                  }
                },
                earliest_timestamp: {
                  top_hits: {
                    sort: [
                      { timestamp: { order: 'asc' } }
                    ],
                    _source: ['timestamp'],
                    size: 1
                  }
                },
                latest_timestamp: {
                  top_hits: {
                    sort: [
                      { timestamp: { order: 'desc' } }
                    ],
                    _source: ['timestamp'],
                    size: 1
                  }
                }
              }
            }
          }
        }

        result = datasource.exec do |client|
          client.search index: datasource.index, body: body
        end

        course_api = Xikolo.api(:course).value!

        sections = []
        Xikolo.paginate(
          course_api.rel(:sections).get(course_id: params[:course_id])
        ) do |section|
          sections << section
        end

        rich_text_items.map do |item|
          id = item['id']
          ri = item(id, from_result: result)

          section = sections.find {|section| section['id'] == item['section_id'] }

          {
            id: id,
            position: "#{section['position']}.#{item['position']}",
            title: item['title'],
            total_clicks: ri&.dig('doc_count').to_i,
            total_clicks_unique_users: ri&.dig('user', 'value').to_i,
            earliest_timestamp: ri&.dig('earliest_timestamp', 'hits', 'hits', 0, '_source', 'timestamp'),
            latest_timestamp: ri&.dig('latest_timestamp', 'hits', 'hits', 0, '_source', 'timestamp')
          }
        end
      end

      def self.item(id, from_result:)
        from_result.dig('aggregations', 'items', 'buckets')&.find do |ri|
          ri['key'] == id
        end
      end

      def self.rich_text_items(course_id)
        rich_texts = []
        Xikolo.paginate(
          Xikolo.api(:course).value!.rel(:items).get(
            course_id: course_id,
            content_type: 'rich_text'
          )
        ) do |video|
          rich_texts.append(video)
        end
        rich_texts
      end

    end
  end
end
