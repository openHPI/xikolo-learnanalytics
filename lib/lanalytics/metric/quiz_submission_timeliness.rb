module Lanalytics
  module Metric
    class QuizSubmissionTimeliness < ExpApiMetric

      description 'Returns the average time to the quiz submission deadline when submitting a quiz.'

      optional_parameter :user_id, :course_id

      exec do |params|
        user_id = params[:user_id]
        course_id = params[:course_id]
        timeliness_script = "(doc['in_context.quiz_submission_deadline'].value - doc['timestamp'].value)"

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [{ match: { verb: 'SUBMITTED_QUIZ' } }] +
                  all_filters(user_id, course_id, nil) +
                  [{ exists: { field: 'in_context.quiz_submission_deadline' }}]
              }
            },
            aggs: {
              stats_submit: {
                stats: {
                  script: {
                    lang: 'painless',
                    source: "#{timeliness_script} / 1000.0 / 60.0"
                  }
                }
              }
            }
          }
        end

        stats = result.dig('aggregations', 'stats_submit')

         {
          submission_count: stats['count'],
          min_minutes: stats['min']&.round,
          max_minutes: stats['max']&.round,
          avg_minutes: stats['avg']&.round
        }
      end
    end
  end
end
