module Lanalytics
  module Metric
    class CourseActivity < CombinedMetric
      def self.dependent_metrics
        [
          { class: PinboardActivity, weight: 0.5 },
          { class: VisitCount }
        ]
      end
    end
  end
end
