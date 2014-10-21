require 'json'

class Lanalytics::Model::StmtComponent
  attr_reader :type

  def initialize(type)

    raise ArgumentError.new("'type' argument cannot be nil") unless type.is_a? String or type.is_a? Symbol
    raise ArgumentError.new("'type' argument cannot be empty") if type.is_a? String and type.empty?
    @type = type.to_sym
  end

  # JSON Serialization (Marshalling)
  def to_json(*a)
    {
        :json_class => self.class.name,
        :data => self.as_json
    }.to_json(*a)
  end

  def ==(other)
    unless other.class == self.class
      return false
    end
    return @type == other.type
  end
  alias_method :eql?, :==

end