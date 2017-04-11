module Lanalytics
  module Metric
    class VideoSpeedChangeMetric < ExpApiCountMetric

      def self.query(_user_id, _course_id, _start_time, _end_time, _resource_id, page, per_page)
        result = datasource.exec do |client|
          client.count index: datasource.index, body: {
            query: {
              bool: {
                must: { match: { verb: 'VIDEO_CHANGE_SPEED' } }
              }
            }
          }
        end

        { count: result['count'] }
      end

    end
  end
end
