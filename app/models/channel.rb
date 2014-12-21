class Channel

  attr_reader :name, :usage, :documentation_url, :settings 

  def initialize(name, usage, documentation_url)
    @name, @usage, @documentation_url = name, usage, documentation_url
  end

  def description
    return @description if @description

    return usage
  end

  def access_channel_as(user, datasource)

  end

end