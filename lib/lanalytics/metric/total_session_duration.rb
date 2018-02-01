module Lanalytics
  module Metric
    class TotalSessionDuration < Base

      description 'The total duration of all sessions.'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['total_session_duration'],
          [params[:user_id]]
        ).first['total_session_duration'].to_i
      end

    end
  end
end
