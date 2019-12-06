# frozen_string_literal: true

module Lanalytics
  module Metric
    class UnenrollmentCount < ExpEventsCountElasticMetric
      event_verbs %w[UN_ENROLLED]
    end
  end
end
