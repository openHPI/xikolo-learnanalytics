class WebAppChannel < Channel
  attr_reader :url

  def initialize(name, usage, documentation_url, url)
    super(name, usage, documentation_url)
    @url = url
  end

  def access_channel_as(user, datasource)
    
  end

end