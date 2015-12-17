module Lanalytics
  module Metric
    class UserActivityCount < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        #default 30 min
        start_time = start_time.present? ? DateTime.parse(start_time) : (DateTime.now - 30.minutes)
        end_time = end_time.present? ? DateTime.parse(end_time) : (DateTime.now)
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
              size:0,
              query: {
                  filtered: {
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
        result['hits']['total']
      end

    end
  end
end
