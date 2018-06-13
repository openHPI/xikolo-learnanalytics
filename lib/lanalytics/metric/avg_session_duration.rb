module Lanalytics
  module Metric
    class AvgSessionDuration < ClusteringMetric

      description 'The total duration of all sessions divided by the amount of sessions.'

      dimension_name 'average_session_duration'

    end
  end
end
