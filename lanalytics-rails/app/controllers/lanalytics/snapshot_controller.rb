class Lanalytics::SnapshotController < ApplicationController

  def snapshot

    ressource_snapshots = []

    if LANALYTICS_CONFIG[:snapshot_handlers].is_a?(String)
      ressource_snapshots += get_snapshots_from_handler(LANALYTICS_CONFIG[:snapshot_handlers])
    elsif LANALYTICS_CONFIG[:snapshot_handlers].is_a?(Array)
      LANALYTICS_CONFIG[:snapshot_handlers].each do | snapshot_handler_name |
        ressource_snapshots += get_snapshots_from_handler(snapshot_handler_name) 
      end
    else
      raise "No snapshot handlers defined in #{LANALYTICS_CONFIG_FILE}. Please include it"
    end

    ressource_snapshots.each { | ressource_snapshot | process_snapshot(ressource_snapshot) }

    render json: { status: "ok" }
  end

  private
  def get_snapshots_from_handler(snapshot_handler_class_name)
    ressource_snapshot_handler = "#{snapshot_handler_class_name}".constantize.new
    ressource_snapshots = ressource_snapshot_handler.current_ressource_snapshots
    
    return ressource_snapshots if ressource_snapshots.is_a?(Array)

    return [ressource_snapshots] if ressource_snapshots.is_a?(Hash) or ressource_snapshots.is_a?(Lanalytics::RessourceSnapshot)

  end

  private
  def process_snapshot(ressource_snapshot)

    ressource_snapshot.ressources.each do | lanalytics_ressource_model |
      lanalytics_ressource_model_event = {
        verb: 'UPDATE',
        ressource_type: ressource_snapshot.type,
        ressource: lanalytics_ressource_model
      }
      puts "#{lanalytics_ressource_model_event}"
      Msgr.publish(lanalytics_ressource_model_event, to: "lanalytics.domain.model")
    end

  end
end