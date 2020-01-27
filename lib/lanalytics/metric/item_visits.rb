# frozen_string_literal: true

module Lanalytics
  module Metric
    class ItemVisits < ExpEventsElasticMetric

      description 'Total and unique user item visits; for last day, last 15 minutes (now) and overall.'

      required_parameter :resource_id

      exec do |params|
        resource_id = params[:resource_id]
        total_item_visits = get_data resource_id, false, false
        total_item_visits_24 = get_data resource_id, true, false
        total_item_visits_now = get_data resource_id, false, true

        result = {}

        result[:total_item_visits] =
          total_item_visits[:hits][:total][:value]
        result[:total_item_visits_24] =
          total_item_visits_24[:hits][:total][:value]
        result[:total_item_visits_now] =
          total_item_visits_now[:hits][:total][:value]
        result[:users_visited] =
          total_item_visits[:aggregations][:distinct_user_count][:value]
        result[:users_visited_24] =
          total_item_visits_24[:aggregations][:distinct_user_count][:value]
        result[:users_visiting_now] =
          total_item_visits_now[:aggregations][:distinct_user_count][:value]
        result
      end

      def self.get_data(resource_id, last_day_only = false, now_only = false)
        query = {
          size: 0,
          track_total_hits: true,
          query: {
            bool: {
              must: [
                { match: { 'resource.resource_uuid' => resource_id } },
                { match: { verb: 'visited_item' } }
              ]
            }
          }
        }

        if last_day_only
          start_time = DateTime.now - 1.day
          end_time = DateTime.now
          query[:query][:bool][:filter] = {
            range: {
              timestamp: {
                gte: DateTime.parse(start_time.to_s).iso8601,
                lte: DateTime.parse(end_time.to_s).iso8601
              }
            }
          }
        end

        if now_only
          start_time = DateTime.now - 15.minutes
          end_time = DateTime.now
          query[:query][:bool][:filter] = {
            range: {
              timestamp: {
                gte: DateTime.parse(start_time.to_s).iso8601,
                lte: DateTime.parse(end_time.to_s).iso8601
              }
            }
          }
        end

        query[:aggs] = {
          distinct_user_count: {
            cardinality: {
              field: 'user.resource_uuid'
            }
          }
        }

        result = datasource.exec do |client|
          client.search index: datasource.index, body: query
        end
        result.with_indifferent_access
      end

    end
  end
end
