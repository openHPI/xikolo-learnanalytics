module Lanalytics
  module Metric
    class PinboardWatchCount < ExpEventsCountElasticMetric
      event_verbs %w(VISITED_PINBOARD VISITED_QUESTION)
    end
  end
end
