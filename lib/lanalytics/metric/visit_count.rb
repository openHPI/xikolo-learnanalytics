module Lanalytics
  module Metric
    class  VisitCount < ExpApiCountMetric
      def self.verbs
        @verbs ||= %w(VISITED)
      end
    end
  end
end
