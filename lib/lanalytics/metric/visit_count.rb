module Lanalytics
  module Metric
    class VisitCount < ExpApiCountMetric
      def self.verbs
        @verbs ||= %w( VISITED_QUESTION VISITED_PROGRESS VISITED_LEARNING_ROOMS
                       VISITED_ANNOUNCEMENTS VISITED_RECAP VISITED_ITEM VISITED_PINBOARD)
      end
    end
  end
end
