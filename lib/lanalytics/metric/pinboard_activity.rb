# frozen_string_literal: true

module Lanalytics
  module Metric
    class PinboardActivity < CombinedMetric
      dependent_metrics [
        {class: PinboardPostingActivity},
        {class: PinboardWatchCount, weight: 0.2}
      ]
    end
  end
end
