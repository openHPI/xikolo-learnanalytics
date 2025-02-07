# frozen_string_literal: true

module Lanalytics
  module Metric
    class QuizPerformance < ExpEventsElasticMetric
      description 'Measures the average percentage of correct answers over all quizzes taken.'

      required_parameter :user_id, :course_id

      optional_parameter :resource_id

      exec do |params|
        user_id = params[:user_id]
        course_id = params[:course_id]
        resource_id = params[:resource_id]

        query = {
          bool: {
            must: [
              {match: {verb: 'SUBMITTED_QUIZ'}},
            ] + all_filters(user_id, course_id, nil),
          },
        }

        query[:bool][:must] <<
          if resource_id.present?
            {match_phrase: {'in_context.item_id' => resource_id}}
          else
            {match_phrase: {'in_context.quiz_type' => 'selftest'}}
          end

        quiz_statements = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            track_total_hits: true,
            query:,
            aggs: {
              sum_points: {
                sum: {field: 'in_context.points'},
              },
              sum_max_points: {
                sum: {field: 'in_context.max_points'},
              },
              avg_attempts: {
                avg: {field: 'in_context.attempt'},
              },
            },
          }
        end

        query[:bool][:must] << {match_phrase: {'in_context.attempt' => 1}}

        quiz_statements_first_attempt = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query:,
            aggs: {
              sum_points: {
                sum: {field: 'in_context.points'},
              },
              sum_max_points: {
                sum: {field: 'in_context.max_points'},
              },
            },
          }
        end

        sum_points = quiz_statements.dig('aggregations', 'sum_points', 'value')
        sum_max_points = quiz_statements.dig('aggregations', 'sum_max_points', 'value')
        avg = sum_max_points.zero? ? 0 : (sum_points / sum_max_points.to_f * 100)
        sum_points_first_attempt =
          quiz_statements_first_attempt.dig(
            'aggregations',
            'sum_points',
            'value',
          )
        sum_max_points_first_attempt = quiz_statements_first_attempt.dig(
          'aggregations',
          'sum_max_points',
          'value',
        )
        first_attempt_avg =
          sum_max_points_first_attempt.zero? ? 0 : (sum_points_first_attempt / sum_max_points_first_attempt.to_f * 100)

        {
          total: quiz_statements.dig('hits', 'total', 'value'),
          average_points_percentage: avg,
          avg_attempts: quiz_statements.dig(
            'aggregations',
            'avg_attempts',
            'value',
          ).to_i,
          average_points_percentage_first_attempt: first_attempt_avg,
        }
      end
    end
  end
end
