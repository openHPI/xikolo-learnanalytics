# frozen_string_literal: true

require_relative 'stmt_component'

module Lanalytics
  module Model
    class StmtResource < Lanalytics::Model::StmtComponent
      attr_reader :uuid, :properties

      def initialize(type, uuid, properties = {})
        super(type)

        raise ArgumentError.new "'uuid' argument cannot be nil" unless uuid
        raise ArgumentError.new "'uuid' argument cannot be empty" if uuid.to_s.empty?

        @uuid = uuid.to_s

        properties ||= {}
        @properties = properties.with_indifferent_access
      end

      def as_json
        {
          type: @type,
          uuid: @uuid,
        }
      end

      def self.new_from_json(json)
        if json.is_a? Hash
          json = json.with_indifferent_access
        elsif json.is_a? String
          json = JSON.parse(json, symbolize_names: true) if json.is_a? String
        elsif !json
          raise ArgumentError.new "'json' cannot be nil"
        else
          raise ArgumentError.new "'json' argument is not a JSON Hash or String"
        end

        new(json[:type], json[:uuid])
      end

      # JSON Deserialization
      # {
      #    "json_class"   => self.class.name,
      #    "data"         => {"type" => @type, "uuid" => @uuid }
      # }
      def self.json_create(json)
        new_from_json(json['data'])
      end

      # Implementing the required interface for marshalling objects, see http://ruby-doc.org/core-2.1.3/Marshal.html
      def _dump(_level)
        [@type, @uuid].join(':|stmt_resource|:')
      end

      def self._load(marshalled_stmt_resource)
        new(*marshalled_stmt_resource.split(':|stmt_resource|:'))
      end

      def ==(other)
        return false unless other.class == self.class

        @type == other.type && @uuid == other.uuid
      end
      alias eql? ==
    end
  end
end
