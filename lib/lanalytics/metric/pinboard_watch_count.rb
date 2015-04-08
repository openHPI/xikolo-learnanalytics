module Lanalytics
  module Metric
    class  PinboardWatchCount < ExpApiCountMetric
      def self.verbs
        @verbs ||= %w(WATCHED_QUESTION)
      end
    end
  end
end
