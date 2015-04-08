module Lanalytics
  module Metric
    class  VisitCount < ExpApiCountMetric
      def self.verbs
        @verbs ||= %w(VISITED_ITEM)
      end
    end
  end
end
