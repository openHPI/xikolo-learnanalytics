module Lanalytics
  module Metric
    class QuestionResponseTime < ExpEventsElasticMetric

      description 'Average time between asked and answered question.'

      required_parameter :user_id, :course_id

      optional_parameter :start_date, :end_date

      exec do |params|
        user_id = params[:user_id]
        course_id = params[:course_id]
        start_date = params[:start_date]
        end_date = params[:end_date]

        answer_statements = datasource.exec do |client|
          query = {
            query: {
              bool: {
                must: [
                  { match: { verb: 'ANSWERED_QUESTION' } }
                ] + (all_filters(user_id, course_id, nil))
              }
            }
          }
          query[:query][:bool][:filter] = {
            range: {
              timestamp: {
                gte: DateTime.parse(start_date).iso8601,
                lte: DateTime.parse(end_date).iso8601
              }
            }
          } if start_date.present? and end_date.present?

          client.search index: datasource.index, body: query
        end['hits']['hits']

        { average: calculate_average(answer_statements) }
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
                    { match_phrase: { 'resource.resource_uuid' => question_id } },
                    { match: { verb: 'ASKED_QUESTION' } }
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

        return nil if response_times.empty?

        response_times.sum.to_f / response_times.size
      end

    end
  end
end
