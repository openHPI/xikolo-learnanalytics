module Lanalytics
  module Metric
    class ItemVisits < ExpApiMetric

      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        total_item_visits = get_data resource_id, false, false
        total_item_visits_24 = get_data resource_id, true, false
        total_item_visits_now = get_data resource_id, false, true
        result = {}
        result[:total_item_visits] = total_item_visits[:hits][:total]
        result[:total_item_visits_24] = total_item_visits_24[:hits][:total]
        result[:total_item_visits_now] = total_item_visits_24[:hits][:total]
        result[:users_visited] = total_item_visits[:aggregations][:distinct_user_count][:value]
        result[:users_visited_24] = total_item_visits_24[:aggregations][:distinct_user_count][:value]
        result[:users_visiting_now] = total_item_visits_24[:aggregations][:distinct_user_count][:value]
        result
      end


      def self.get_data resource_id, last_day_only = false, now_only = false
        conditions = [
            {
                match_phrase: {
                    'resource.resource_uuid' => resource_id
                }
            },
            {
                match: {
                    verb: verbs.join(' OR ')
                }
            }
        ]

        if last_day_only
          start_time = DateTime.now - 1.day
          end_time = DateTime.now
          filter = {
              range: {
                  timestamp: {
                      gte: DateTime.parse(start_time.to_s).iso8601,
                      lte: DateTime.parse(end_time.to_s).iso8601
                  }
              }
          }
          conditions << filter
        end

        if now_only
          start_time = DateTime.now - 15.minutes
          end_time = DateTime.now
          filter = {
              range: {
                  timestamp: {
                      gte: DateTime.parse(start_time.to_s).iso8601,
                      lte: DateTime.parse(end_time.to_s).iso8601
                  }
              }
          }
          conditions << filter
        end

        query = {
            size: 0,
            query: {
                bool: {
                    must: conditions
                }
            }
        }

        query[:aggs] =  {
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

      def self.verbs
        %w( VISITED_QUESTION VISITED_PROGRESS VISITED_LEARNING_ROOMS
            VISITED_ANNOUNCEMENTS VISITED_RECAP VISITED_ITEM VISITED_PINBOARD)
      end

    end
  end
end
