module Lanalytics
  module Metric
    class VideoEvents < ExpApiMetric

      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        pause = get_data('VIDEO_PAUSE', resource_id, nil)
        play = get_data('VIDEO_PLAY', resource_id, nil)
        change_speed = get_data('VIDEO_CHANGE_SPEED', resource_id, nil)
        seek = get_data('VIDEO_SEEK', resource_id, nil, 'in_context.new_current_time' )
        stop = get_data('VIDEO_STOP', resource_id, nil)
        fullscreen = get_data('VIDEO_FULLSCREEN', resource_id,  {match_phrase: { 'in_context.new_state' => 'fullscreen'}})
        fullscreen_off = get_data('VIDEO_FULLSCREEN', resource_id,  {match_phrase: { 'in_context.new_state' => 'player'}})
        result = {}
        result = add_to_total(result, pause, 'pause')
        result = add_to_total(result, play, 'play')
        result = add_to_total(result, change_speed, 'change_speed')
        result = add_to_total(result, stop, 'stop')
        result = add_to_total(result, seek, 'seek')
        result = add_to_total(result, fullscreen, 'fullscreen')
        result = add_to_total(result, fullscreen_off, 'fullscreen_off')

        result
      end

      def self.add_to_total(result, collection, key)
        collection.each do |item|
          unless result[item['key']].present?
            result[item['key']] = {}
            result[item['key']]['time'] = item['key']
          end

          if result[item['key']]['total'].blank?
            result[item['key']]['total'] = 0
          end
          result[item['key']]['total'] += item['doc_count']

          result[item['key']][key] = item['doc_count']
        end

        result
      end

      def self.get_data verb, resource_id, add_filter = nil, timefield = "in_context.current_time"
        conditions = [
          {
            match_phrase: {
              'resource.resource_uuid' => resource_id
            }
          },
          {
            match: {
              verb: verb
            }
          }
        ]
        conditions << add_filter if add_filter.present?
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: conditions
              }
            },
            aggs: {
              timestamps: {
                histogram: {
                  field: timefield,
                  interval: '15',
                  min_doc_count: '0'
                }
              }
            }
          }
        end

        result['aggregations']['timestamps']['buckets']
      end

    end
  end
end
