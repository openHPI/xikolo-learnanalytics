# frozen_string_literal: true

module Lanalytics
  module Metric
    class ProgressVisitsCount < ExpEventsCountElasticMetric
      event_verbs %w[VISITED_PROGRESS]
    end
  end
end
