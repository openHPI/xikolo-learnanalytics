class Lanalytics::RessourceSnapshot
  attr_reader :ressources, :type

  def initialize(type, ressources = [])
    unless type
      raise "Type requires String, but is #{type.class}: #{type}"
    end

    @type = type
    @ressources = ressources
  end

end