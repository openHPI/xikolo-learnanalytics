module Lanalytics
  module Metric
    class QuizPointsTimebased < ExpEventsElasticMetric

      description 'Returns the cumulated scored and maximum points for quizzes(!) over the specified time span (per day).'

      required_parameter :start_date, :end_date

      optional_parameter :user_id, :course_id

      exec do |params|
        user_id = params[:user_id]
        course_id = params[:course_id]
        start_date = params[:start_date]
        end_date = params[:end_date]

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [{ match: { verb: 'SUBMITTED_QUIZ' } }] + all_filters(user_id, course_id, nil),
                must_not: [{ term: { 'in_context.quiz_type': 'survey' } }],
                filter: {
                  range: {
                    timestamp: {
                      gte: DateTime.parse(start_date).iso8601,
                      lte: DateTime.parse(end_date).iso8601
                    }
                  }
                }
              }
            },
            aggs: {
              by_day: {
                date_histogram: {
                  field: 'timestamp',
                  interval: '1d',
                  min_doc_count: 0,
                  extended_bounds: {
                    min: DateTime.parse(start_date).iso8601,
                    max: DateTime.parse(end_date).iso8601
                  }
                },
                aggs: {
                  points_stats: {
                    sum: {field: 'in_context.points'}
                  },
                  max_points_stats: {
                    sum: {field: 'in_context.max_points'}
                  },
                  cumulative_points: {
                    cumulative_sum: {
                      buckets_path: 'points_stats'
                    }
                  },
                  cumulative_max_points: {
                    cumulative_sum: {
                      buckets_path: 'max_points_stats'
                    }
                  },
                }
              }
            }
          }
        end

        points_progression result.dig('aggregations', 'by_day', 'buckets')
      end

      private

      def self.points_progression(buckets)
        buckets&.each_with_object({}) do |b, h|
          h[Time.parse(b['key_as_string'].to_s).utc.strftime('%F')] = {
            cumulative_points: b.dig('cumulative_points', 'value').round(2),
            cumulative_max_points: b.dig('cumulative_max_points', 'value').round(2)
          }
        end
      end
    end
  end
end
