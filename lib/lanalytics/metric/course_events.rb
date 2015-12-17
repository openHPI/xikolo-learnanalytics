module Lanalytics
  module Metric
    class CourseEvents < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_time, resource_id=nil, page, per_page)
        page = 1 if page == nil
        per_page = 100 if per_page == nil
        from = (page.to_i-1)*per_page

        course_id = nil unless course_id.present? # handle empty state
        start_time = start_time.present? ? DateTime.parse(start_time) : (DateTime.now - 1.day)
        end_time = end_time.present? ? DateTime.parse(end_time) : (DateTime.now)

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
              size: per_page,
              from: from,
              query: {
                  filtered: {
                      query: {
                          bool: {
                              must: [
                                  {
                                      match: {
                                          verb: verbs.join(' OR ')
                                      }
                                  }
                              ] + (all_filters(course_id))
                          }
                      },
                      filter: {
                              range: {
                                  timestamp: {
                                      gte: start_time.iso8601,
                                      lte: end_time.iso8601
                                  }
                              }
                      }
                  }
              }
          }
        end

        processed_result = []

        result['hits']['hits'].each do |item|
          ev = {
              course_id: item['_source']['in_context']['course_id'],
              verb: item['_source']['verb'],
              user: item['_source']['user']['resource_uuid'],
              timestamp:  item['_source']['timestamp'],
              resource: item['_source']['resource']['resource_uuid'],
              action: item['_source']['verb'] + ' ' + item['_source']['resource']['resource_uuid']
          }
          processed_result << ev
        end

        processed_result
        #first alpha pagination support
        current_last = result['hits']['hits'].count + (page.to_i-1)*per_page
        result = {data:processed_result, next: current_last < result['hits']['total'] }

      end

      # this is the list of events we would like, all must have the course id
      def self.verbs
        %w(VIEWED_PAGE, WATCHED_QUESTION, VISITED)
      end
    end
  end
end
