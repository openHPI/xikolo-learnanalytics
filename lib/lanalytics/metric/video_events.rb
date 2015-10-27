module Lanalytics
  module Metric
    class VideoEvents < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_time, ressource_id)
        pause = get_data('VIDEO_PAUSE', ressource_id, nil)
        play = get_data('VIDEO_PLAY', ressource_id, nil)
        change_speed = get_data('VIDEO_CHANGE_SPEED', ressource_id, nil)
        stop = get_data('VIDEO_STOP', ressource_id, nil)
        seek = get_data('VIDEO_SEEK', ressource_id, nil)
        fullscreen = get_data('VIDEO_FULLSCREEN', ressource_id,  {match_phrase: { 'in_context.new_state' => 'fullscreen'}})
        fullscreen_off = get_data('VIDEO_FULLSCREEN', ressource_id,  {match_phrase: { 'in_context.new_state' => 'player'}})
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
        fullscreen_off.each do |item|
          result[item['key']]['fullscreen_off'] = item['doc_count']
          result[item['key']]['total'] += item['doc_count']
        end
        result
      end


      def self.get_data verb, ressource_id, add_filter = nil
        conditions = [
            {match_phrase: { 'resource.resource_uuid' => ressource_id}},
            {match: {verb: verb}}
        ]
        conditions << add_filter  if add_filter.present?
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