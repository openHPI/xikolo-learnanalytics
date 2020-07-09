# frozen_string_literal: true

module Lanalytics
  module Metric
    class QuizSubmissionTimeliness < ExpEventsElasticMetric
      description <<~DOC
        Returns the average time to the quiz submission deadline when submitting a quiz.
      DOC

      optional_parameter :user_id, :course_id

      exec do |params|
        user_id = params[:user_id]
        course_id = params[:course_id]

        timeliness_script = <<~SCRIPT
          if (doc['timestamp'].size() == 0) return 0;
          if (doc['in_context.quiz_submission_deadline'].size() == 0) return 0;

          long time = doc['in_context.quiz_submission_deadline'].value.getMillis() - doc['timestamp'].value.getMillis();

          time / 1000.0 / 60.0;
        SCRIPT

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [
                  {match: {verb: 'SUBMITTED_QUIZ'}},
                  {exists: {field: 'in_context.quiz_submission_deadline'}},
                ].append(
                  user_filter(user_id),
                  course_filter(course_id),
                ).compact,
              },
            },
            aggs: {
              stats_submit: {
                stats: {
                  script: {
                    lang: 'painless',
                    source: timeliness_script,
                  },
                },
              },
            },
          }
        end

        stats = result.dig('aggregations', 'stats_submit')

        {
          submission_count: stats['count'],
          min_minutes: stats['min']&.round,
          max_minutes: stats['max']&.round,
          avg_minutes: stats['avg']&.round,
        }
      end
    end
  end
end
