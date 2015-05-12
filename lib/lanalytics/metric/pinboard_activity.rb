module Lanalytics
  module Metric
    class  PinboardActivity < CombinedMetric
      def self.dependent_metrics
        [{class: PinboardPostingActivity},
         {class: PinboardWatchCount, weight: 0.2}]
      end
    end
  end
end
