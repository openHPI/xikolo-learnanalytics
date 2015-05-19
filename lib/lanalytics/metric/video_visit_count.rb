module Lanalytics
  module Metric
    class  VideoVisitCount < ExpApiCountMetric
      def self.verbs
        @verbs ||= %w(VISITED)
      end

      def self.filters
        [{match_phrase: {'resource.content_type' => 'video'}}]
      end
    end
  end
end
