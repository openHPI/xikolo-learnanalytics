module Lanalytics
  module Metric
    class CoursePoints < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_date, ressource_id)
        completed_statements = datasource.exec do |client|
          client.search index: datasource.index, body: {
            query: {
              filtered: {
                query: {
                  bool: {
                    must: [
                      {match_phrase: {'user.resource_uuid' => user_id}},
                      {match: {verb: 'COMPLETED_COURSE'}}
                    ] + (all_filters(course_id))
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
        end['hits']['hits']

        return {points: nil} if completed_statements.empty?

        {points: completed_statements.first['_source']['in_context']['points_achieved']}
      end
    end
  end
end
