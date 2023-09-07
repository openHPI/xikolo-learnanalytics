# frozen_string_literal: true

module Lanalytics
  module Metric
    class ItemVisitsCount < ExpEventsCountElasticMetric
      event_verbs %w[VISITED_ITEM]
    end
  end
end
