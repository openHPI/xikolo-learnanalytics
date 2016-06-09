module Lanalytics
  module Metric
    class PinboardWatchCount < ExpApiCountMetric
      def self.verbs
        @verbs ||= %w(VISITED_PINBOARD, VISITED_QUESTION)
      end
    end
  end
end
