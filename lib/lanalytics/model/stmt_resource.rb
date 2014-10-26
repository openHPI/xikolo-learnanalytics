require_relative 'stmt_component'

class Lanalytics::Model::StmtResource < Lanalytics::Model::StmtComponent
  attr_reader :uuid, :properties

  def initialize(type, uuid, properties = {})
    super(type)

    raise ArgumentError.new("'uuid' argument cannot be nil") unless uuid
    @uuid = uuid.to_s
    raise ArgumentError.new("'uuid' argument cannot be empty") if uuid.empty?

    properties ||= {}
    @properties = properties.with_indifferent_access
  end

  def as_json
    {
      :type => @type,
      :uuid => @uuid
    }
  end

  def self.new_from_json(json)

    if json.is_a? Hash
      json = json.with_indifferent_access
    elsif json.is_a? String
      json = JSON.parse(json, symbolize_names: true) if json.is_a? String
    elsif not json
      raise "'json' cannot be nil"
    else
      raise "'json' argument is not a JSON Hash or String"
    end

    return new(json[:type], json[:uuid])
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
  def _dump level
    return [@type, @uuid].join(':|stmt_resource|:')
  end

  def self._load(marshalled_stmt_resource)
    return new(*marshalled_stmt_resource.split(':|stmt_resource|:'))
  end

  def == (other)
    unless other.class == self.class
      return false
    end
    return (@type == other.type and @uuid == other.uuid)
  end
  alias_method :eql?, :==

end