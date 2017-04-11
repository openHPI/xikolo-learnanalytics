module Lanalytics
  module Metric
    class PinboardPostingActivity < ExpApiCountMetric

      def self.verbs
        @verbs ||= %w(ASKED_QUESTION ANSWERED_QUESTION COMMENTED)
      end

    end
  end
end
