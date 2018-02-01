module Lanalytics
  module Metric
    class MainQuizPerformance < Base

      description 'The average percentage of correct answers in weekly homework assignment quizzes (graded).'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['main_quiz_performance'],
          [params[:user_id]]
        ).first['main_quiz_performance'].to_i
      end

    end
  end
end
