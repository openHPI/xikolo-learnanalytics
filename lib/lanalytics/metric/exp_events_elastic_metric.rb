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
        return if course_id.nil?

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

      def self.user_filter(user_id)
        return if user_id.nil?

        {match: {'user.resource_uuid' => user_id}}
      end

      def self.resource_filter(resource_id)
        return if resource_id.nil?

        {match: {'resource.resource_uuid' => resource_id}}
      end

      def self.resources_filter(resource_ids)
        return if resource_ids.blank?

        {
          bool: {
            minimum_should_match: 1,
            should: resource_ids.map {|id| {match: {'resource.resource_uuid' => id}} },
          },
        }
      end

      def self.date_filter(start_date, end_date)
        return if start_date.nil? && end_date.nil?

        df = {range: {timestamp: {}}}

        df[:range][:timestamp][:gte] = DateTime.parse(start_date).iso8601 if start_date.present?

        df[:range][:timestamp][:lte] = DateTime.parse(end_date).iso8601 if end_date.present?

        df
      end

      # deprecated, use the more specific filter methods instead
      def self.all_filters(user_id, course_id, resource_id)
        af = [
          course_filter(course_id),
          user_filter(user_id),
          resource_filter(resource_id),
        ].compact

        af + filters
      end

      # deprecated
      def self.filters
        []
      end
    end
  end
end
