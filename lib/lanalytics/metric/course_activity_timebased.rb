module Lanalytics
  module Metric
    class CourseActivityTimebased < ExpApiMetric

      description 'Returns course statistics time-based.'

      required_parameter :start_date, :end_date

      optional_parameter :user_id, :course_id, :resource_id

      exec do |params|
        user_id = params[:user_id]
        course_id = params[:course_id]
        resource_id = params[:resource_id]
        start_date = params[:start_date]
        end_date = params[:end_date]

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: all_filters(user_id, course_id, resource_id),
                filter: {
                  range: {
                    timestamp: {
                      gte: DateTime.parse(start_date).iso8601,
                      lte: DateTime.parse(end_date).iso8601
                    }
                  }
                }
              }
            },
            aggs: {
              timestamps: {
                date_histogram: {
                  field: 'timestamp',
                  interval: user_id.present? ? 'day' : 'hour',
                  min_doc_count: 0
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

    end
  end
end
