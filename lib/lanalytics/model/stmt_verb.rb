require_relative 'stmt_component'

class Lanalytics::Model::StmtVerb < Lanalytics::Model::StmtComponent

  def initialize(type)
    super(type)
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

    return new(json[:type])
  end

  def to_json(*a)
    {
        "json_class"   => self.class.name,
        "data"         => {"type" => @type }
    }.to_json(*a)
  end
end