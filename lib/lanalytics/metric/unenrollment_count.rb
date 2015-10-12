module Lanalytics
  module Metric
    class  UnenrollmentCount < ExpApiCountMetric
      def self.verbs
        @verbs ||= %w(UN_ENROLLED)
      end
    end
  end
end
