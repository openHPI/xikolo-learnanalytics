# frozen_string_literal: true

module Lanalytics
  module Metric
    class ExpEventsCountElasticMetric < ExpEventsElasticMetric
      def self.verbs
        @verbs ||= []
      end

      def self.event_verbs(verbs)
        @verbs = verbs

        description "Counts the following events: #{verbs.join(', ').downcase}."
        optional_parameter :user_id, :course_id, :start_date, :end_date

        @exec = proc do |params|
          user_id = params[:user_id]
          course_id = params[:course_id]
          start_date = params[:start_date]
          end_date = params[:end_date]

          result = datasource.exec do |client|
            query = {
              query: {
                bool: {
                  must: [] + verbs_filter + all_filters(user_id, course_id, nil),
                },
              },
            }
            if start_date.present? && end_date.present?
              query[:query][:bool][:filter] = {
                range: {
                  timestamp: {
                    gte: DateTime.parse(start_date).iso8601,
                    lte: DateTime.parse(end_date).iso8601,
                  },
                },
              }
            end

            client.count index: datasource.index, body: query
          end
          {count: result['count']}
        end
      end

      def self.verbs_filter
        return [] if verbs.nil? || verbs.size == 0

        filter = [{bool: {should: []}}]
        verbs.each do |verb|
          filter[0][:bool][:should] << {match: {verb:}}
        end
        filter
      end
    end
  end
end
