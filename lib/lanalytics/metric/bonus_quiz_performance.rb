module Lanalytics
  module Metric
    class BonusQuizPerformance < Base

      description 'Measures the average percentage of correct answers in bonus quizzes (optional, but graded if taken).'

      optional_parameter :user_id, :course_id

      exec do |params|
        Lanalytics::Clustering::Dimensions.query(
          params[:course_id],
          ['bonus_quiz_performance'],
          [params[:user_id]]
        ).first['bonus_quiz_performance'].to_i
      end

    end
  end
end
