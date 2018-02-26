module Lanalytics
  module Metric
    class ForumObservation < Base

      description 'The sum of question subscriptions, question visits and other forum-related navigational events.'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['forum_observation'],
          [params[:user_id]]
        ).first['forum_observation'].to_i
      end

    end
  end
end
