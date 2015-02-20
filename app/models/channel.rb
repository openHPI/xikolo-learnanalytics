class Channel

  attr_reader :name, :usage, :documentation_url 

  def initialize(name, usage, documentation_url)
    @name, @usage, @documentation_url = name, usage, documentation_url
  end

  def description
    return @description if @description

    return usage
  end

  def access_channel_for(user, datasource, research_case)
    raise NotImplementedError("This method has to be implemented in the subclass!")
  end

  def to_json
    return self.as_json.to_json
  end

  def as_json
    return {
      class_name: self.class.name,
      name: @name,
      usage: @usage,
      documentation_url: @documentation_url
    }
  end

  def self.load(json)
    json = JSON.load(json.to_str)
    name, usage, documentation_url = json['name'], json['usage'], json['documentation_url']
    return self.new(name, usage, documentation_url)
  end

  def self.dump(channel)

    unless channel.is_a?(self)
      raise ::ActiveRecord::SerializationTypeMismatch,
        "Attribute was supposed to be a #{self}, but was a #{channel.class}. -- #{channel.inspect}"
    end

    return JSON.dump(channel.as_json)
  end

end