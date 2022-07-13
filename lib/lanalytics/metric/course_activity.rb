# frozen_string_literal: true

module Lanalytics
  module Metric
    class CourseActivity < CombinedMetric
      dependent_metrics [
        {class: PinboardActivity, weight: 0.5},
        {class: VisitCount}
      ]
    end
  end
end
