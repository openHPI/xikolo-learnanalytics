module Lanalytics
  module Metric
    class  PinboardActivity < ExpApiCountMetric
      def self.verbs
        @verbs ||= %w(ASKED_QUESTION ANSWERED_QUESTION COMMENTED WATCHED_QUESTION)
      end
    end
  end
end
