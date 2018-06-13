module Lanalytics
  module Metric
    class UngradedQuizPerformance < ClusteringMetric

      description 'The average percentage of correct answers in ungraded quizzes (not influencing the final course score).'

      dimension_name 'ungraded_quiz_performance'

    end
  end
end
