module Lanalytics
  class TrackingController < ApplicationController
    def track

      raw_tracking_event_actor = params.require(:actor)
      raw_tracking_event_verb = params.require(:verb)
      raw_tracking_event_object = params.require(:ressource)

      tracking_event = {
         actor: { :actor_id => raw_tracking_event_actor[:attributes][:id] },
         verb: raw_tracking_event_verb,
         object: raw_tracking_event_object,
         with_result: nil,
         in_context: nil,
         timestamp: DateTime.now.to_i
      }

      puts "#{tracking_event}"

      Msgr.publish(tracking_event, to: "logstash-routing-key")
      puts "Event in event queue"

      render json: { status: "ok" }
    end

    def bulk_track
    end

    private
    def log_params
      params.permit("actor", "verb", "object")
    end
  end
end
