# frozen_string_literal: true

module Lanalytics
  module Metric
    class QuizSubmitDuration < ExpEventsElasticMetric
      description <<~DOC
        Returns the total time, i.e., duration, needed for working on a quiz and
        the comparison with quizzes for which a time effort exists.
      DOC

      optional_parameter :user_id, :course_id

      exec do |params|
        user_id = params[:user_id]
        course_id = params[:course_id]

        duration_filter_script = <<~SCRIPT
          if (doc['timestamp'].size() == 0) return false;
          if (doc['in_context.quiz_access_time'].size() == 0) return false;

          long duration = doc['timestamp'].value.getMillis() - doc['in_context.quiz_access_time'].value.getMillis();

          (duration / 1000) < params.three_hours;
        SCRIPT

        duration_script = <<~SCRIPT
          if (doc['timestamp'].size() == 0) return 0;
          if (doc['in_context.quiz_access_time'].size() == 0) return 0;

          long duration = doc['timestamp'].value.getMillis() - doc['in_context.quiz_access_time'].value.getMillis();

          duration / 1000;
        SCRIPT

        estimated_time_script = <<~SCRIPT
          if (doc['in_context.estimated_time_effort'].size() == 0) return 0;

          StrictMath.ceil(doc['in_context.estimated_time_effort'].value / 60.0);
        SCRIPT

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [
                  {match: {verb: 'SUBMITTED_QUIZ'}},
                ].append(
                  user_filter(user_id),
                  course_filter(course_id),
                ).compact,
                # Reduce inconsistencies due to not submitted quizzes; can be
                # removed when quiz submission time is fixed in the quiz service
                filter: {
                  script: {
                    script: {
                      source: duration_filter_script,
                      lang: 'painless',
                      params: {
                        three_hours: 10_800,
                      },
                    },
                  },
                },
              },
            },
            aggs: {
              item_ids: {
                terms: {
                  field: 'in_context.item_id',
                  size: 500,
                },
              },
              stats_actual_time: {
                stats: {
                  script: {
                    lang: 'painless',
                    source: duration_script,
                  },
                },
              },
              with_estimation: {
                filter: {exists: {field: 'in_context.estimated_time_effort'}},
                aggs: {
                  stats_actual_time: {
                    stats: {
                      script: {
                        lang: 'painless',
                        source: duration_script,
                      },
                    },
                  },
                  stats_estimated_time: {
                    stats: {
                      script: {
                        lang: 'painless',
                        source: estimated_time_script,
                      },
                    },
                  },
                },
              },
            },
          }
        end

        actual_time =
          result.dig('aggregations', 'stats_actual_time')
        comparable_time =
          result.dig('aggregations', 'with_estimation', 'stats_actual_time')
        estimated_time =
          result.dig('aggregations', 'with_estimation', 'stats_estimated_time')

        {
          num_submissions: actual_time['count'],
          actual_time: {
            min_seconds: actual_time['min'],
            max_seconds: actual_time['max'],
            avg_seconds: actual_time['avg'],
            sum_seconds: actual_time['sum'],
          },
          comparison: {
            num_submissions: comparable_time['count'],
            actual_time: {
              min_seconds: comparable_time['min'],
              max_seconds: comparable_time['max'],
              avg_seconds: comparable_time['avg'],
              sum_seconds: comparable_time['sum'],
            },
            estimated_time_effort: {
              min_minutes: estimated_time['min'],
              max_minutes: estimated_time['max'],
              avg_minutes: estimated_time['avg'],
              sum_minutes: estimated_time['sum'],
            },
          },
        }
      end
    end
  end
end
