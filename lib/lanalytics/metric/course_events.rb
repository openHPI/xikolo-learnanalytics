module Lanalytics
  module Metric
    class CourseEvents < ExpApiMetric

      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page, scroll_id)
        page = 1 if page == nil
        per_page = 1000 if per_page == nil

        course_id = nil unless course_id.present? # handle empty state
        start_time = start_time.present? ? DateTime.parse(start_time) : (DateTime.now - 1.day)
        end_time = end_time.present? ? DateTime.parse(end_time) : (DateTime.now)

        if scroll_id.nil?
          result = datasource.exec do |client|
            client.search index: datasource.index,
                          scroll: '5m',
                          body: {
                            query: {
                              bool: {
                                minimum_should_match: 1,
                                should: [
                                  { match: { 'in_context.course_id' => course_id } },
                                  { match: { 'resource.resource_uuid' => course_id } }
                                ],
                                filter: {
                                  range: {
                                    timestamp: {
                                      gte: start_time.iso8601,
                                      lte: end_time.iso8601
                                    }
                                  }
                                }
                              }
                            },
                            sort: ['_doc'],
                            size: per_page
                          }
          end
        else
          result = datasource.exec do |client|
            client.scroll scroll: '5m', scroll_id: scroll_id, body: { scroll_id: scroll_id }
          end
        end

        processed_result = []

        result['hits']['hits'].each do |item|
          ev = {
              course_id: item['_source']['in_context']['course_id'],
              user: item['_source']['user']['resource_uuid'],
              verb: item['_source']['verb'],
              resource: item['_source']['resource']['resource_uuid'],
              timestamp:  item['_source']['timestamp'],
              context: item['_source']['in_context'].to_json
          }
          processed_result << ev
        end

        current_last = result['hits']['hits'].count + (page.to_i - 1) * per_page
        return { data: processed_result, next: current_last < result['hits']['total'], scroll_id: result['_scroll_id'], total_pages: (result['hits']['total']/per_page.to_f).ceil }
      end

    end
  end
end
