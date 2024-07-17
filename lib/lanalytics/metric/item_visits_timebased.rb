# frozen_string_literal: true

module Lanalytics
  module Metric
    class ItemVisitsTimebased < ExpEventsElasticMetric
      description 'Returns the cumulated unique and total visits over the specified time span (per day).'

      required_parameter :start_date, :end_date

      optional_parameter :user_id, :course_id

      exec do |params|
        user_id = params[:user_id]
        course_id = params[:course_id]
        start_date = params[:start_date]
        end_date = params[:end_date]

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [{match: {verb: 'VISITED_ITEM'}}] + all_filters(user_id, course_id, nil),
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
              day_histogram: {
                date_histogram: {
                  field: 'timestamp',
                  interval: '1d',
                  min_doc_count: 0,
                  extended_bounds: {
                    min: DateTime.parse(start_date).iso8601,
                    max: DateTime.parse(end_date).iso8601,
                  },
                },
                aggs: {
                  cumulative_total_visits: {
                    cumulative_sum: {
                      buckets_path: '_count',
                    },
                  },
                  by_resource: {
                    terms: {
                      field: 'resource.resource_uuid',
                      size: 30_000,
                    },
                  },
                },
              },
            },
          }
        end

        {
          unique_visits: unique_visits(result.dig('aggregations', 'day_histogram', 'buckets')),
          total_visits: total_visits(result.dig('aggregations', 'day_histogram', 'buckets')),
        }
      end

      private

      def self.unique_visits(buckets)
        visited_items = []
        buckets&.each_with_object({}) do |b, h|
          bucket_visits = b.dig('by_resource', 'buckets')&.map {|e| e['key'] }
          new_visits = bucket_visits - visited_items
          visited_items += new_visits
          h[Time.parse(b['key_as_string'].to_s).utc.strftime('%F')] = {
            visits: new_visits.size,
            cumulative_visits: visited_items.size,
          }
        end
      end

      def self.total_visits(buckets)
        buckets&.each_with_object({}) do |b, h|
          h[Time.parse(b['key_as_string'].to_s).utc.strftime('%F')] = {
            visits: b['doc_count'],
            cumulative_visits: b.dig('cumulative_total_visits', 'value').to_i,
          }
        end
      end
    end
  end
end
