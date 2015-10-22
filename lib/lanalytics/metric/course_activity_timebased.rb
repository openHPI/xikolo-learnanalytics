module Lanalytics
  module Metric
    class CourseActivityTimebased < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_time, ressource_id)
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              filtered: {
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
                      'in_context.course_id' => course_id
                    }
                  }]
                }
              }
            },
            aggs: {
              timestamps: {
                date_histogram: {
                  field: 'timestamp',
                  interval: 'hour'
                }
              }
            }
          }
        end

        convert_to_timestamps(result.with_indifferent_access[:aggregations][:timestamps][:buckets])
      end

      def self.convert_to_timestamps(buckets)
        # Convert to a hash of timestamps and quantity 1
        # (needed for cal-heatmap)
        Hash[
          buckets.map do |bucket|
            [
              DateTime.parse(bucket[:key_as_string]).to_i,
              bucket[:doc_count]
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
