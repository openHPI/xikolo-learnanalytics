# frozen_string_literal: true

require 'date'

module Lanalytics
  module Model
    class ExpApiStatement
      attr_reader :user, :verb, :resource, :timestamp, :with_result, :in_context

      def initialize(user, verb, resource, timestamp = DateTime.now, with_result = {}, in_context = {})
        unless user.is_a? Lanalytics::Model::StmtUser
          raise ArgumentError.new "'user' argument cannot be nil and should be Lanalytics::Model::StmtUser"
        end

        @user = user

        unless verb.is_a? Lanalytics::Model::StmtVerb
          raise ArgumentError.new "'verb' argument cannot be nil and should be Lanalytics::Model::StmtVerb"
        end

        @verb = verb

        unless resource.is_a? Lanalytics::Model::StmtResource
          raise ArgumentError.new "'resource' argument cannot be nil and should be Lanalytics::Model::StmtResource"
        end

        @resource = resource

        timestamp = DateTime.now if timestamp.nil?
        unless timestamp.is_a?(DateTime) || timestamp.is_a?(String)
          raise ArgumentError.new "'timestamp' argument should be DateTime or String"
        end

        timestamp = DateTime.parse(timestamp) if timestamp.is_a? String
        @timestamp = timestamp

        @with_result = with_result.to_hash

        @in_context = in_context.to_hash
      end

      def properties
        {
          timestamp: @timestamp.to_s,
          with_result: @with_result.symbolize_keys,
          in_context: @in_context.symbolize_keys,
        }
      end

      def as_json
        {
          user: @user.as_json,
          verb: @verb.as_json,
          resource: @resource.as_json,
          timestamp: @timestamp,
          with_result: @with_result,
          in_context: @in_context,
        }
      end

      def self.new_from_json(json)
        if json.is_a? Hash
          json = json.with_indifferent_access
        elsif json.is_a? String
          json = JSON.parse(json, symbolize_names: true)
        elsif json.nil?
          raise ArgumentError.new "'json' cannot be nil"
        else
          raise ArgumentError.new "'json' argument is not a JSON Hash or String"
        end

        new(
          Lanalytics::Model::StmtUser.new_from_json(json[:user]),
          Lanalytics::Model::StmtVerb.new_from_json(json[:verb]),
          Lanalytics::Model::StmtResource.new_from_json(json[:resource]),
          json[:timestamp],
          json[:with_result],
          json[:in_context],
        )
      end

      def to_json(*ary)
        {
          json_class: self.class.name,
          data: as_json,
        }.to_json(*ary)
      end

      def self.json_create(json_hash)
        new_from_json(json_hash['data'])
      end

      # Implementing the required interface for marshalling objects, see http://ruby-doc.org/core-2.1.3/Marshal.html
      def _dump(_level)
        [@user, @verb, @resource, @timestamp, @with_result, @in_context].map do |attribute|
          Marshal.dump(attribute)
        end.join(':|exp_api_stmt|:')
      end

      def self._load(serialized_stmt_array)
        new(*serialized_stmt_array.split(':|exp_api_stmt|:').map! {|arg| Marshal.load(arg) })
      end

      # Implementing the equals method
      def ==(other)
        return false unless other.class == self.class

        @user == other.user &&
          @verb == other.verb &&
          @resource == other.resource &&
          @timestamp == other.timestamp &&
          @with_result == other.with_result &&
          @in_context == other.in_context
      end
      alias eql? ==
    end
  end
end
