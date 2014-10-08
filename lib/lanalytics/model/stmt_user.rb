class Lanalytics::Model::StmtUser < Lanalytics::Model::StmtResource

  def initialize(uuid)
    super(:User, uuid)
  end

  def self.new_from_json(json)
    if json.is_a? Hash
      json = json.with_indifferent_access
    elsif json.is_a? String
      json = JSON.parse(json, symbolize_names: true) if json.is_a? String
    else
      raise "'json' argument is not a JSON Hash or String"
    end

    return new(json[:uuid])
  end

  def _dump(level)
    return @uuid.to_s
  end

  def self._load(marshalled_stmt_user)
    return new(marshalled_stmt_user)
  end

end