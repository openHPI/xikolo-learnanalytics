# frozen_string_literal: true

module Lanalytics
  module Metric
    class VisitCount < ExpEventsCountElasticMetric
      event_verbs %w[
        VISITED_QUESTION
        VISITED_PROGRESS
        VISITED_LEARNING_ROOMS
        VISITED_ANNOUNCEMENTS
        VISITED_RECAP
        VISITED_ITEM
        VISITED_PINBOARD
      ]
    end
  end
end
