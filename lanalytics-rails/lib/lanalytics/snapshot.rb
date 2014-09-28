class Lanalytics::Snapshot
  attr_reader :ressources, :ressource_type

  def initiatlize(ressource_type, ressources = [])
    unless ressource_type
      raise "ressource_type cannot be nil"
    end

    @ressource_type = ressource_type
    @ressources = ressources
  end

end