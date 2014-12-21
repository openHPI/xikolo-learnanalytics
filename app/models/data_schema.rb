class Datasource

  attr_reader :key, :title, :technology

  def initialize(key, title, technology)
    @key, @title, @technology = key, title, technology
  end

end