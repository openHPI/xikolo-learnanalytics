module Lanalytics
  module Metric
    class VideoVisitCount < ExpApiCountMetric

      event_verbs %w(VISITED_ITEM)

      def self.filters
        [ { match: { 'resource.content_type' => 'video' } } ]
      end

    end
  end
end
