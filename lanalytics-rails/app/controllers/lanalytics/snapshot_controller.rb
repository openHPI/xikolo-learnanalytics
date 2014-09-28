class Lanalytics::SnapshotController < ApplicationController
  
  # before_action :check_lanalytics_configuration

  # def check_lanalytics_configuration
  #   if not Rails.application.config.lanalytics
  #     puts "Do something"
  #   end
  # end

  def snapshot

    # if config.lanalytics config.lanalytics.snapshot_handlers
    # snapshot_ressources = config.lanalytics.snapshot_handlers.inject([]) do | current_ressource_snapshot, snapshot_handler |
    #   current_ressource_snapshot + snapshot_handler.current_ressource_snapshot
    # end

    # LANALYTICS_CONFIG[:snapshot_handlers]

    # ressource_snapshot = current_ressource_snapshot
    ressource_snapshot_handler = "#{LANALYTICS_CONFIG[:snapshot_handlers]}".constantize.new
    ressource_snapshot = ressource_snapshot_handler.current_ressource_snapshot

    ressource_snapshot[:ressources].each do | lanalytics_ressource_model |
      lanalytics_ressource_model_event = {
        verb: 'UPDATE',
        ressource_type: ressource_snapshot[:ressource_type],
        ressource: lanalytics_ressource_model
      }
      Msgr.publish(lanalytics_ressource_model_event, to: "lanalytics.domain.model")
    end

    render json: { status: "ok" }
  end
end