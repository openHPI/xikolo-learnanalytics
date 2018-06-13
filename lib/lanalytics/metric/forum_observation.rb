module Lanalytics
  module Metric
    class ForumObservation < ClusteringMetric

      description 'The sum of question subscriptions, question visits and other forum-related navigational events.'

      dimension_name 'forum_observation'

    end
  end
end
