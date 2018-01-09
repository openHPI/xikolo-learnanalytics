module Lanalytics
  module Metric
    class  UserEnrollmentCount < ExpApiCountMetric

      def self.verbs
        @verbs ||= %w(ENROLLED)
      end

    end
  end
end
