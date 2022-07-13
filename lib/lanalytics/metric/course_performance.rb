# frozen_string_literal: true

module Lanalytics
  module Metric
    class CoursePerformance < ClusteringMetric
      description 'Achieved course performance (points achieved / max points).'

      dimension_name 'course_performance'
    end
  end
end
