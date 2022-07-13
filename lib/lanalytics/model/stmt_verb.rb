# frozen_string_literal: true

require_relative 'stmt_component'

module Lanalytics
  module Model
    class Lanalytics::Model::StmtVerb < Lanalytics::Model::StmtComponent
      def initialize(type)
        super(type)
      end

      def as_json
        {
          type: @type,
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

        new(json[:type])
      end
    end
  end
end
