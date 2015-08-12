module Lanalytics
  module Metric
    class CourseActivityTimebased < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_time)
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 10000,
            filter: {
              and: [{
                range: {
                  timestamp: {
                    gte: DateTime.parse(start_time).iso8601,
                    lte: DateTime.parse(end_time).iso8601
                  }
                }
              }, {
                term: {
                  'in_context.course_id': course_id
                }
              }]
            },
            fields: %w(timestamp)
          }
        end

        convert_to_timestamps(result.with_indifferent_access[:hits][:hits])
      end

      def self.convert_to_timestamps(hits)
        # Convert to a hash of timestamps and quantity 1
        # (needed for cal-heatmap)
        Hash[
          hits.map do |hit|
            [
              DateTime.parse(hit[:fields][:timestamp][0]).to_i,
              1
            ]
          end
        ]
      end

      def self.verbs
        []
      end
    end
  end
end
