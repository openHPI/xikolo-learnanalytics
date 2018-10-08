class WebAppChannel < Channel
  attr_reader :url, :usage_doc

  def initialize(name, usage, documentation_url, url, usage_doc = '')
    super(name, usage, documentation_url)
    @url, @usage_doc = url, usage_doc
  end

  def access_channel_for(user, datasource, research_case)
    datasource.authenticate_user(user)
  end

  def as_json
    super.as_json.merge(url: @url, usage_doc: @usage_doc)
  end

  def self.load(json)
    json = JSON.load(json.to_str)
    
    json['usage_doc'] ||= ''
    name, usage, documentation_url, url, usage_doc = json['name'], json['usage'], json['documentation_url'], json['url'], json['usage_doc']
    return self.new(name, usage, documentation_url, url, usage_doc)
  end
end
