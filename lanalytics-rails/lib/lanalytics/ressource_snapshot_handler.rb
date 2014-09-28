class Lanalytics::RessourceSnapshotHandler

  def current_ressource_snapshots
    raise 'This method should be implemented in the subclass'
  end

  protected
  def new_ressource_snapshot_for_type_with_ressources(ressource_type, ressources)
    return Lanalytics::RessourceSnapshot.new(ressource_type, ressources)
  end

end