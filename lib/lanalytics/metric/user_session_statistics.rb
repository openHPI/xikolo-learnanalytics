# frozen_string_literal: true

module Lanalytics
  module Metric
    class UserSessionStatistics < Base

      description 'Returns all session statistics for the user as well as all course participants by querying the respective session metrics.'

      required_parameter :course_id, :user_id

      def self.datasource_keys
        %w[exp_events_elastic exp_events_postgres google_analytics]
      end

      exec do |params|
        course_id = params[:course_id]
        user_id = params[:user_id]

        # we need to query the number of users with events in course, to
        # calculate the average per user for Google Analytics metrics
        elastic = Lanalytics::Processing::DatasourceManager.datasource(
          'exp_events_elastic',
        )
        user_result = elastic.exec do |client|
          client.search index: elastic.index, body: {
            size: 0,
            query: {
              bool: {
                must: [
                  {
                    bool: {
                      minimum_should_match: 1,
                      should: [
                        {match: {'in_context.course_id' => course_id}},
                        {match: {'resource.resource_uuid' => course_id}},
                      ],
                    },
                  },
                ],
              },
            },
            aggs: {
              distinct_user_count: {
                cardinality: {
                  field: 'user.resource_uuid',
                  precision_threshold: 40_000,
                },
              },
            },
          }
        end

        user_count = user_result
          .dig('aggregations', 'distinct_user_count', 'value').to_f

        session_durations = SessionDurations.query(course_id: course_id)

        {
          user_avg_sessions:
            AvgSessionDuration.query(course_id: course_id, user_id: user_id),
          user_total_sessions:
            TotalSessionDuration.query(course_id: course_id, user_id: user_id),
          user_sessions:
            Sessions.query(course_id: course_id, user_id: user_id),
          course_avg_sessions:
            session_durations[:avg_session_duration],
          course_total_sessions:
            session_durations[:total_session_duration] / user_count,
          course_sessions:
            session_durations[:total_sessions] / user_count,
        }
      end
    end
  end
end
