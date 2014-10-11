require 'date'
#require_relative 'stmt_user'
#require_relative 'stmt_verb'
#require_relative 'stmt_resource'

class Lanalytics::Model::ExpApiStatement
  attr_reader :user, :verb, :resource, :timestamp, :with_result, :in_context

  def initialize(user, verb, resource, timestamp = DateTime.now, with_result = {}, in_context = {})

    raise ArgumentError.new("'user' argument cannot be nil and should be Lanalytics::Model::StmtUser") unless user.is_a? Lanalytics::Model::StmtUser
    @user = user

    raise ArgumentError.new("'verb' argument cannot be nil and should be Lanalytics::Model::StmtVerb") unless verb.is_a? Lanalytics::Model::StmtVerb
    @verb = verb

    raise ArgumentError.new("'resource' argument cannot be nil and should be Lanalytics::Model::StmtResource") unless resource.is_a? Lanalytics::Model::StmtResource
    @resource = resource

    timestamp ||= DateTime.now
    raise ArgumentError.new("'timestamp' argument should be DateTime or String") unless timestamp.is_a? DateTime or timestamp.is_a? String
    timestamp = DateTime.parse(timestamp) if timestamp.is_a? String
    @timestamp = timestamp

    with_result ||= {}
    @with_result = with_result.to_hash

    in_context ||= {}
    @in_context = in_context.to_hash
  end

  def self.new_from_json(json)

    if json.is_a? Hash
      json = json.with_indifferent_access
    elsif json.is_a? String
      json = JSON.parse(json, symbolize_names: true) if json.is_a? String
    elsif not json.nil?
      raise ArgumentError.new("'json' cannot be nil")
    else
      raise ArgumentError.new("'json' argument is not a JSON Hash or String")
    end

    return new(
        Lanalytics::Model::StmtUser.new_from_json(json[:user]),
        Lanalytics::Model::StmtVerb.new_from_json(json[:verb]),
        Lanalytics::Model::StmtResource.new_from_json(json[:resource]),
        json[:timestamp],
        json[:with_result],
        json[:in_context]
    )
  end

  def to_json(*a)
    {
        :json_class => self.class.name,
        :data => {
            :user => JSON.dump(@user),
            :verb => JSON.dump(@verb),
            :resource => JSON.dump(@resource),
            :timestamp => @timestamp,
            :with_result => @with_result,
            :in_context => @in_context
        }
    }.to_json(*a)
  end

  #def actor_uuid
  #
  #end
  #
  #def ressource_uuid
  #  return self.ressource.uuid
  #end

  # Implementing the required interface for marshalling objects, see http://ruby-doc.org/core-2.1.3/Marshal.html
  def _dump level
    [@user, @verb, @resource, @timestamp, @with_result, @in_context].map do | attribute |
      Marshal.dump(attribute)
    end.join(':|exp_api_stmt|:')
  end

  def self._load(serialized_stmt_array)
    new(*serialized_stmt_array.split(':|exp_api_stmt|:').map! { | arg | Marshal.load(arg) })
  end

  def ==(other)
    unless other.class == self.class
      return false
    end
    return (@user == other.user and @verb == other.verb and @resource == other.resource and @timestamp == other.timestamp and @with_result == other.with_result and @in_context == other.in_context)
  end
  alias_method :eql?, :==
end