module Lanalytics
  module Metric
    class AvgSessionDuration < Base

      description 'The total duration of all sessions divided by the amount of sessions.'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['average_session_duration'],
          [params[:user_id]]
        ).first['average_session_duration'].to_i
      end

    end
  end
end
