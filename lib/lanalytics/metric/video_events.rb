# frozen_string_literal: true

module Lanalytics
  module Metric
    class VideoEvents < ExpEventsElasticMetric
      description 'Counts per video event type.'

      required_parameter :resource_id

      exec do |params|
        resource_id = params[:resource_id]

        pause =          get_data('VIDEO_PAUSE', resource_id)
        play =           get_data('VIDEO_PLAY', resource_id)
        change_speed =   get_data('VIDEO_CHANGE_SPEED', resource_id)
        seek =           get_data('VIDEO_SEEK', resource_id)
        stop =           get_data('VIDEO_STOP', resource_id)
        fullscreen =     get_data('VIDEO_FULLSCREEN', resource_id,
          {match: {'in_context.new_state' => 'fullscreen'}})
        fullscreen_off = get_data('VIDEO_FULLSCREEN', resource_id, {match: {'in_context.new_state' => 'player'}})

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
          if result[item['key']].blank?
            result[item['key']] = {}
            result[item['key']]['time'] = item['key']
          end

          result[item['key']]['total'] = 0 if result[item['key']]['total'].blank?
          result[item['key']]['total'] += item['doc_count']

          result[item['key']][key] = item['doc_count']
        end

        result
      end

      def self.get_data(verb, resource_id, add_filter = nil)
        conditions = [
          {
            match: {
              'resource.resource_uuid' => resource_id,
            },
          },
          {
            match: {
              verb:,
            },
          },
        ]

        conditions << add_filter if add_filter.present?

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: conditions,
              },
            },
            aggs: {
              timestamps: {
                histogram: {
                  field: 'in_context.current_time',
                  interval: '15',
                  min_doc_count: '0',
                },
              },
            },
          }
        end

        result['aggregations']['timestamps']['buckets']
      end
    end
  end
end
