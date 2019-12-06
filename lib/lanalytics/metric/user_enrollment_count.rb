# frozen_string_literal: true

module Lanalytics
  module Metric
    class UserEnrollmentCount < ExpEventsCountElasticMetric
      event_verbs %w[ENROLLED]
    end
  end
end
