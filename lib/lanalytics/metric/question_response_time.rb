module Lanalytics
  module Metric
    class QuestionResponseTime < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_date)
        answer_statements = datasource.exec do |client|
          client.search index: datasource.index, body: {
            query: {
              filtered: {
                query: {
                  bool: {
                    must: [
                      {match_phrase: {'user.resource_uuid' => user_id}},
                      {match: {verb: 'ANSWERED_QUESTION'}}
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
        {average: calculate_average(answer_statements)}
      end

      def self.calculate_average(answer_statements)
        response_times = []
        answer_statements.each do |answer_statement|
          answer = answer_statement['_source']
          question_id = answer['in_context']['question_id']
          question = datasource.exec do |client|
            client.search index: datasource.index, body: {
              query: {
                bool: {
                  must: [
                    {match_phrase: {'resource.resource_uuid' => question_id}},
                    {match: {verb: 'ASKED_QUESTION'}}
                  ]
                }
              }
            }
          end['hits']['hits']
          next if question.empty?

          question_time = Time.parse(question.first['_source']['timestamp'])
          answer_time = Time.parse(answer['timestamp'])
          response_times << answer_time - question_time
        end
        if response_times.empty?
          nil
        else
          response_times.sum.to_f / response_times.size
        end
      end
    end
  end
end
