module Lanalytics
  module Metric
    class UngradedQuizPerformance < Base

      description 'The average percentage of correct answers in ungraded quizzes (not influencing the final course score).'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['ungraded_quiz_performance'],
          [params[:user_id]]
        ).first['ungraded_quiz_performance'].to_i
      end

    end
  end
end
