require 'date'
#require_relative 'stmt_user'
#require_relative 'stmt_verb'
#require_relative 'stmt_resource'

module Lanalytics::Model
  # Always a directed grpah d
  class ExpApiStatement
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
      else
        raise "'json' argument is not a JSON Hash or String"
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
    def marshal_dump
      [@user, @verb, @ressource, @timestamp, @with_result, @in_context]
    end

    def marshal_load(serialized_stmt_array)
      @user, @verb, @ressource, @timestamp, @with_result, @in_context = serialized_stmt_array
    end

    # All static methods
    class << self
      def from(serialized_stmt = nil)

        return nil unless serialized_stmt


      end


    end
  end
end