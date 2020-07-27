# frozen_string_literal: true

module Lanalytics
  module Metric
    class ActiveUsersByDaytime < ExpEventsElasticMetric

      description 'Counts the number of activities per day of week and hour'

      required_parameter :start_date, :end_date

      optional_parameter :course_id

      exec do |params|
        start_date = params[:start_date]
        end_date = params[:end_date]

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [course_filter(params[:course_id])].compact,
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
            aggregations: {
              timestamps: {
                date_histogram: {
                  field: 'timestamp',
                  interval: 'hour',
                  min_doc_count: 0,
                  extended_bounds: {
                    min: DateTime.parse(start_date).iso8601,
                    max: DateTime.parse(end_date).iso8601,
                  },
                },
                aggregations: {
                  user: {
                    cardinality: {
                      field: 'user.resource_uuid',
                    },
                  },
                },
              },
            },
          }
        end

        user_by_wday(result.dig('aggregations', 'timestamps', 'buckets'))
      end

      def self.user_by_wday(buckets)
        by_hour = buckets.each_with_object({}) do |bucket, hours|
          time = Time.zone.parse bucket['key_as_string']
          hours[time.hour] ||= wday_scaffold
          hours[time.hour][time.wday][:user] += bucket['user']['value']
          hours[time.hour][time.wday][:bucket_count] += 1
        end

        result = []

        by_hour.each do |hour, w_days|
          w_days.each do |w_day, data|
            result.append(
              day_of_week: w_day,
              hour: hour,
              avg_users: data[:user].to_f / data[:bucket_count],
            )
          end
        end

        result.sort_by {|a| [a[:day_of_week], a[:hour]] }
      end

      def self.wday_scaffold
        {
          0 => {user: 0, bucket_count: 0},
          1 => {user: 0, bucket_count: 0},
          2 => {user: 0, bucket_count: 0},
          3 => {user: 0, bucket_count: 0},
          4 => {user: 0, bucket_count: 0},
          5 => {user: 0, bucket_count: 0},
          6 => {user: 0, bucket_count: 0},
        }
      end
    end
  end
end
