module Lanalytics
  module Metric
    class ExpApiCountMetric < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_date, ressource_id)
        result = datasource.exec do |client|
          client.count index: datasource.index, body: {
            query: {
              filtered: {
                query: {
                  bool: {
                    must: [
                      {match: {verb: verbs.join(' OR ')}}
                    ] + (all_filters(course_id, user_id))
                  }
                },
                filter: {
                  range: {
                    timestamp: {
                      gte: DateTime.parse(start_time).iso8601,
                      lte: DateTime.parse(end_date).iso8601
                    }
                  }
                }
              }
            }
          }
        end
        {count: result['count']}
      end

      def self.verbs
        []
      end
    end
  end
end
