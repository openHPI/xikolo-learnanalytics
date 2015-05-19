module Lanalytics
  module Metric
    class VideoSpeedChangeMetric < ExpApiCountMetric
      def self.query(user_id, course_id, start_time, end_time)
        result = datasource.exec do |client|
          client.count index: datasource.index, body: {
            query: {
                filtered: {
                    query: {
                        bool: {
                            must: {match: {verb: 'VIDEO_CHANGE_SPEED'}}
                        }
                    }

                }
            }
          }
        end
        {count: result['count']}
      end
    end
  end
end
