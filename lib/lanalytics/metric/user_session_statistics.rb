module Lanalytics
  module Metric
    class UserSessionStatistics < ExpApiMetric

      description 'Returns all session statistics for the user as well as all course participants by querying the respective session metrics.'

      required_parameter :course_id, :user_id

      exec do |params|
        course_id = params[:course_id]
        user_id = params[:user_id]

        session_durations = SessionDurations.query(course_id: course_id)

        {
          user_avg_sessions: AvgSessionDuration.query(course_id: course_id, user_id: user_id),
          user_total_sessions: TotalSessionDuration.query(course_id: course_id, user_id: user_id),
          user_sessions: Sessions.query(course_id: course_id, user_id: user_id),
          course_avg_sessions: session_durations[:avg_session_duration],
          course_total_sessions: session_durations[:total_session_duration],
          course_sessions: session_durations[:total_sessions]
        }
      end
    end
  end
end
