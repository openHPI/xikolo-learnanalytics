module Lanalytics
  module Metric
    class CourseActivityTimebased < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: all_filters(user_id, course_id, resource_id),
                filter: {
                  range: {
                    timestamp: {
                      gte: DateTime.parse(start_time).iso8601,
                      lte: DateTime.parse(end_time).iso8601
                    }
                  }
                }
              }
            },
            aggs: {
              timestamps: {
                date_histogram: {
                  field: 'timestamp',
                  interval: user_id.present? ? 'day' : 'hour'
                }
              }
            }

          }
        end
        convert_to_timestamps(result.with_indifferent_access[:aggregations][:timestamps][:buckets])
      end

      def self.convert_to_timestamps(buckets)
        # Convert to a hash of timestamps and quantity
        # (needed for cal-heatmap)
        Hash[
            buckets.map do |bucket|
              [
                  Time.parse(bucket[:key_as_string].to_s[0..-4]).to_i,
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
