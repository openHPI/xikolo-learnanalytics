# frozen_string_literal: true

module Lanalytics
  module Metric
    class ActiveUsersByDay < ExpEventsElasticMetric
      include Lanalytics::Helper::PercentageHelper
      description 'Counts the number of active users per day and hour.'

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

        result.dig('aggregations', 'timestamps', 'buckets').map do |bucket|
          time = Time.zone.parse(bucket['key_as_string'])

          {
            date: time.strftime('%Y%m%d'),
            total_users: bucket.dig('user', 'value').to_i,
            hour: time.hour,
          }
        end
      end
    end
  end
end
