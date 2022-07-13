module Lanalytics
  module Metric
    class ProgressVisitsCount < ExpEventsCountElasticMetric
      event_verbs %w(VISITED_PROGRESS)
    end
  end
end
