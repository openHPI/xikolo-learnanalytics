module Lanalytics
  module Metric
    class UserSessionStatistics < ExpApiMetric

      description 'Returns all session statistics for the user as well as all course participants by querying the respective session metrics.'

      required_parameter :course_id, :user_id

      exec do |params|
        course_id = params[:course_id]
        user_id = params[:user_id]

        {
          user_avg_sessions: AvgSessionDuration.query(course_id: course_id, user_id: user_id),
          user_total_sessions: TotalSessionDuration.query(course_id: course_id, user_id: user_id),
          user_sessions: Sessions.query(course_id: course_id, user_id: user_id),
          course_avg_sessions: AvgSessionDuration.query(course_id: course_id),
          course_total_sessions: TotalSessionDuration.query(course_id: course_id),
          course_sessions: Sessions.query(course_id: course_id),
        }
      end
    end
  end
end
