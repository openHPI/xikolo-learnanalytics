# frozen_string_literal: true

module Lanalytics
  module Metric
    class ExpEventsElasticMetric < Base
      def self.datasource_keys
        %w[exp_events_elastic]
      end

      def self.datasource
        datasources.first
      end

      def self.course_filter(course_id)
        return nil if course_id.nil?

        {
          bool: {
            minimum_should_match: 1,
            should: [
              {match: {'in_context.course_id' => course_id}},
              {match: {'resource.resource_uuid' => course_id}},
            ],
          },
        }
      end

      def self.date_filter(start_date, end_date)
        return nil if start_date.nil? && end_date.nil?

        df = {range: {timestamp: {}}}

        if start_date.present?
          df[:range][:timestamp][:gte] = DateTime.parse(start_date).iso8601
        end

        if end_date.present?
          df[:range][:timestamp][:lte] = DateTime.parse(end_date).iso8601
        end

        df
      end

      # deprecated
      # rubocop:disable Metrics/MethodLength
      def self.all_filters(user_id, course_id, resource_id)
        filters_ = if course_id.nil?
                     []
                   else
                     [
                       {
                         bool: {
                           minimum_should_match: 1,
                           should: [
                             {match: {'in_context.course_id' => course_id}},
                             {match: {'resource.resource_uuid' => course_id}},
                           ],
                         },
                       },
                     ]
                   end

        filters_ += if user_id.nil?
                      []
                    else
                      [{match: {'user.resource_uuid' => user_id}}]
                    end

        filters_ += if resource_id.nil?
                      []
                    else
                      [{match: {'resource.resource_uuid' => resource_id}}]
                    end

        filters_ + filters
      end
      # rubocop:enable all

      # deprecated
      def self.filters
        []
      end
    end
  end
end
