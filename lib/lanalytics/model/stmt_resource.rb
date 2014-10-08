class Lanalytics::Model::StmtResource < Lanalytics::Model::StmtComponent
  attr_reader :uuid

  def initialize(type)
    raise "'type' argument cannot be nil" unless type.is_a? String or type.is_a? Symbol
    @type = type.to_sym
  end

  def initialize(type, uuid)
    super(type)

    raise "'uuid' argument cannot be nil" unless uuid
    @uuid = uuid.to_s
  end

  def self.new_from_json(json)

    if json.is_a? Hash
      json = json.with_indifferent_access
    elsif json.is_a? String
      json = JSON.parse(json, symbolize_names: true) if json.is_a? String
    else
      raise "'json' argument is not a JSON Hash or String"
    end

    return new(json[:type], json[:uuid])
  end

  # JSON Serialization (Marshalling)
  def to_json(*a)
    {
        "json_class"   => self.class.name,
        "data"         => {"type" => @type, "uuid" => @uuid }
    }.to_json(*a)
  end


  # JSON Deserialization
  # {
  #    "json_class"   => self.class.name,
  #    "data"         => {"type" => @type, "uuid" => @uuid }
  # }
  def self.json_create(json)
    return new_from_json(json["data"])
  end

  # Implementing the required interface for marshalling objects, see http://ruby-doc.org/core-2.1.3/Marshal.html
  def marshal_dump
    [@type, @uuid]
  end

  def marshal_load(serialized_stmt_array)
    @type, @uuid = serialized_stmt_array
  end

  def == (other)
    unless other.class == self.class
      return false
    end
    return @type == other.type && @uuid == other.uuid
  end
  alias_method :eql?, :==

end