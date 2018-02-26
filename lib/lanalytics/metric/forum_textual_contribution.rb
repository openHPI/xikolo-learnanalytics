module Lanalytics
  module Metric
    class ForumTextualContribution < Base

      description 'The sum of questions, comments and answers posted in the forum.'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['textual_forum_contribution'],
          [params[:user_id]]
        ).first['textual_forum_contribution'].to_i
      end

    end
  end
end
