module Lanalytics
  module Metric
    class ItemVisitsCount < ExpApiCountMetric

      event_verbs %w(VISITED_ITEM)

    end
  end
end
