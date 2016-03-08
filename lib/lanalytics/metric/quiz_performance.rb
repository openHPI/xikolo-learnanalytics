module Lanalytics
  module Metric
    class QuizPerformance < ExpApiMetric

      def self.query(user_id, course_id, start_date = nil, end_date = nil, resource_id, page, per_page)
        query = {
          filtered: {
            filter: {
              bool: {
                must: [
                  {match: {verb: 'SUBMITTED_QUIZ'}}
                ] + (all_filters(course_id, user_id))
              }
            }
          }
        }
        if resource_id.present?
          query[:filtered][:filter][:bool][:must] << {match_phrase: {"in_context.item_id" => resource_id}}
        else
          query[:filtered][:filter][:bool][:must] << {match_phrase: {"in_context.quiz_type" => 'selftest'}}
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
        query[:filtered][:filter][:bool][:must] << {match_phrase: {"in_context.attempt" => 1}}
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
        first_attempt_avg = 0
        avg = 0
        avg = quiz_statements["aggregations"]["sum_points"]["value"] / quiz_statements["aggregations"]["sum_max_points"]["value"].to_f * 100 unless quiz_statements["aggregations"]["sum_max_points"]["value"] == 0
        first_attempt_avg = 0
        first_attempt_avg = quiz_statements_first_attempt["aggregations"]["sum_points"]["value"] / quiz_statements_first_attempt["aggregations"]["sum_max_points"]["value"].to_f * 100 unless quiz_statements_first_attempt["aggregations"]["sum_max_points"]["value"] == 0
        return {total: quiz_statements["hits"]["total"],
            average_points_percentage: avg,
            avg_attempts:  quiz_statements["aggregations"]["avg_attempts"]["value"] ||= 0,
            average_points_percentage_first_attempt: first_attempt_avg
        }
      end
    end
  end
end
