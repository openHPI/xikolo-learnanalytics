# frozen_string_literal: true

module Lanalytics
  module Metric
    class UserActivityCount < ExpEventsElasticMetric
      description 'Overall platform activity (events), defaults to 30 minutes.'

      optional_parameter :start_date, :end_date

      exec do |params|
        start_date = params[:start_date]
        end_date = params[:end_date]

        # default 30 min
        start_date = start_date.present? ? DateTime.parse(start_date) : (DateTime.now - 30.minutes)
        end_date = end_date.present? ? DateTime.parse(end_date) : DateTime.now
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            track_total_hits: true,
            query: {
              range: {
                timestamp: {
                  gte: start_date.iso8601,
                  lte: end_date.iso8601,
                },
              },
            },
          }
        end
        result['hits']['total']['value']
      end
    end
  end
end
