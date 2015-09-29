require_relative 'stmt_resource'

module Lanalytics
  module Model
    class Lanalytics::Model::StmtUser < Lanalytics::Model::StmtResource

      def initialize(uuid)
        super(:User, uuid)
      end

      def self.new_from_json(json)
        if json.is_a? Hash
          json = json.with_indifferent_access
        elsif json.is_a? String
          json = JSON.parse(json, symbolize_names: true) if json.is_a? String
        elsif json.nil?
          raise ArgumentError.new "'json' cannot be nil"
        else
          raise ArgumentError.new "'json' argument is not a JSON Hash or String"
        end

        new(json[:uuid])
      end

      def _dump(_level)
        @uuid.to_s
      end

      def self._load(marshalled_stmt_user)
        new(marshalled_stmt_user)
      end

    end
  end
end
