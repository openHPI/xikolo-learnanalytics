module Lanalytics
  module Metric
    class  UserEnrollmentCount < ExpApiCountMetric

      event_verbs %w(ENROLLED)

    end
  end
end
