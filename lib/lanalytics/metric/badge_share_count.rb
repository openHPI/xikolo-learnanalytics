# frozen_string_literal: true

module Lanalytics
  module Metric
    class BadgeShareCount < ExpEventsCountElasticMetric
      event_verbs %w[share_open_badge]
    end
  end
end
