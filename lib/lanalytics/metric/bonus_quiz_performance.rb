module Lanalytics
  module Metric
    class BonusQuizPerformance < ClusteringMetric

      description 'Measures the average percentage of correct answers in bonus quizzes (optional, but graded if taken).'

      dimension_name 'bonus_quiz_performance'

    end
  end
end
