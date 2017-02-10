module Lanalytics
  module Metric
    class VideoVisitCount < ExpApiCountMetric

      def self.verbs
        @verbs ||= %w(VISITED_ITEM)
      end

      def self.filters
        [ { match: { 'resource.content_type' => 'video' } } ]
      end

    end
  end
end
