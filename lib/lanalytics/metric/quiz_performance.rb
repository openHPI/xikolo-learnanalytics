module Lanalytics
  module Metric
    class QuizPerformance < ExpApiMetric

      def self.query(user_id, course_id, start_date, end_date, resource_id, page, per_page)
        query = {
          bool: {
            must: [
              { match: { verb: 'SUBMITTED_QUIZ' } }
            ] + (all_filters(course_id, user_id))
          }
        }
        if resource_id.present?
          query[:bool][:must] << { match_phrase: { 'in_context.item_id' => resource_id } }
        else
          query[:bool][:must] << { match_phrase: { 'in_context.quiz_type' => 'selftest' } }
        end
        quiz_statements = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: query,
            aggs: {
              sum_points: {
                sum: {field: "in_context.points"}
              },
              sum_max_points: {
                sum: {field: "in_context.max_points"}
              },
              avg_attempts: {
                avg: {field: "in_context.attempt"}
              }
            }
          }
        end
        query[:bool][:must] << { match_phrase: { "in_context.attempt" => 1 } }
        quiz_statements_first_attempt = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: query,
            aggs: {
              sum_points: {
                sum: {field: "in_context.points"}
              },
              sum_max_points: {
                sum: {field: "in_context.max_points"}
              },
            }
          }
        end
        sum_points = quiz_statements["aggregations"]["sum_points"]["value"]
        sum_max_points = quiz_statements["aggregations"]["sum_max_points"]["value"]
        avg = sum_max_points != 0 ? sum_points / sum_max_points.to_f * 100 : 0
        sum_points_first_attempt = quiz_statements_first_attempt["aggregations"]["sum_points"]["value"]
        sum_max_points_first_attempt = quiz_statements_first_attempt["aggregations"]["sum_max_points"]["value"]
        first_attempt_avg =
            sum_max_points_first_attempt != 0 ? sum_points_first_attempt / sum_max_points_first_attempt.to_f * 100 : 0
        return {
          total: quiz_statements["hits"]["total"],
          average_points_percentage: avg,
          avg_attempts:  quiz_statements["aggregations"]["avg_attempts"]["value"] ||= 0,
          average_points_percentage_first_attempt: first_attempt_avg
        }
      end

    end
  end
end
