module Lanalytics
  module Metric
    class GradedQuizPerformance < ClusteringMetric

      description 'The average percentage of correct answers in graded quizzes (influencing the final course score).'

      dimension_name 'graded_quiz_performance'

    end
  end
end
