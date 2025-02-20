# frozen_string_literal: true

module Lanalytics
  module Metric
    class UngradedQuizPerformance < ClusteringMetric
      description <<~DOC
        The average percentage of correct answers in ungraded quizzes (not influencing the final course score).
      DOC

      dimension_name 'ungraded_quiz_performance'
    end
  end
end
