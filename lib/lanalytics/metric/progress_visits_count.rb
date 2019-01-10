module Lanalytics
  module Metric
    class ProgressVisitsCount < ExpApiCountMetric

      event_verbs %w(VISITED_PROGRESS)

    end
  end
end
