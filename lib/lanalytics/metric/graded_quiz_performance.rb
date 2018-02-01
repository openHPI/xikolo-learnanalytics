module Lanalytics
  module Metric
    class GradedQuizPerformance < Base

      description 'The average percentage of correct answers in graded quizzes (influencing the final course score).'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['graded_quiz_performance'],
          [params[:user_id]]
        ).first['graded_quiz_performance'].to_i
      end

    end
  end
end
