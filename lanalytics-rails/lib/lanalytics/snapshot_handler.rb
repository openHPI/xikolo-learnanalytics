
class Lanalytics::SnapshotHandler

  def current_ressource_snapshot
    raise 'This method should be implemented in the subclass'
  end

  protected
  def create_ressource_snapshot_for_type_with_ressources()
    return {
       ressource_type: 'Course',
       ressources: courses_ressources
     }
  end

end