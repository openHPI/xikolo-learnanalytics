module Lanalytics
  module Metric
    class VideoEvents < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_time, ressource_id)
        pause = get_data('VIDEO_PAUSE', ressource_id)
        play = get_data('VIDEO_PLAY', ressource_id)
        change_speed = get_data('CHANGE_SPEED', ressource_id)
        stop = get_data('VIDEO_STOP', ressource_id)
        seek = get_data('VIDEO_SEEK', ressource_id)
        fullscreen = get_data('VIDEO_FULLSCREEN', ressource_id)
        result = {}

        pause.each do |item|
          result[item['key']] = {} unless result[item['key']].present?
          result[item['key']]['time'] = item['key']  unless result[item['key']].present?
          result[item['key']]['total'] = item['doc_count']
          result[item['key']]['pause'] = item['doc_count']
        end
        play.each do |item|
          result[item['key']]['play'] = item['doc_count']
          result[item['key']]['total'] = item['doc_count']
        end
        change_speed.each do |item|
          result[item['key']]['change_speed'] = item['doc_count']
          result[item['key']]['total'] += item['doc_count']
        end
        stop.each do |item|
          result[item['key']]['stop'] = item['doc_count']
          result[item['key']]['total'] += item['doc_count']
        end
        seek.each do |item|
          result[item['key']]['seek'] = item['doc_count']
          result[item['key']]['total'] += item['doc_count']
        end
        fullscreen.each do |item|
          result[item['key']]['fullscreen'] = item['doc_count']
          result[item['key']]['total'] += item['doc_count']
        end
        result
      end


      def self.get_data verb, ressource_id
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
                                                   size: 0,
                                                   query: {
                                                       bool: {
                                                           must: [
                                                               {match_phrase: { 'resource.resource_uuid' => ressource_id}},
                                                               {match: {verb: verb}}
                                                           ]
                                                       }
                                                   },
                                                   aggs: {
                                                       timestamps: {
                                                           histogram: {
                                                               field: 'in_context.current_time',
                                                               interval: '15',
                                                               min_doc_count: '0'
                                                           }
                                                       }
                                                   }
                                               }
          end
          result["aggregations"]["timestamps"]["buckets"]
        end

    end
  end
end
