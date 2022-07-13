# frozen_string_literal: true

module Lanalytics
  module Metric
    class CourseActivityTimebased < ExpEventsElasticMetric
      description 'Returns the course activities within the specified time span grouped by the day of week and hour of the day.'

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
                      lte: DateTime.parse(end_date).iso8601,
                    },
                  },
                },
              },
            },
            aggs: {
              timestamps: {
                date_histogram: {
                  field: 'timestamp',
                  interval: user_id.present? ? '1h' : '1d',
                  min_doc_count: 0,
                  extended_bounds: {
                    min: DateTime.parse(start_date).iso8601,
                    max: DateTime.parse(end_date).iso8601,
                  },
                },
              },
            },
          }
        end

        activities_by_wday result.dig('aggregations', 'timestamps', 'buckets')
      end

      def self.activities_by_wday(buckets)
        # Convert to a hash of days/hours and quantity
        # Format day0: { hour0: quantity, hour1: quantity }
        # For weekdays, 0 is Sunday
        buckets.each_with_object({}) do |bucket, hours|
          time = Time.parse bucket['key_as_string']
          hours[time.hour] ||= wday_scaffold
          hours[time.hour][time.wday] += bucket['doc_count']
        end
      end

      def self.wday_scaffold
        {
          0 => 0,
          1 => 0,
          2 => 0,
          3 => 0,
          4 => 0,
          5 => 0,
          6 => 0,
        }
      end
    end
  end
end
