# frozen_string_literal: true

require 'json'

module Lanalytics
  module Model
    class StmtComponent
      attr_reader :type

      def initialize(type)
        raise ArgumentError.new "'type' argument cannot be nil" unless type.is_a?(String) || type.is_a?(Symbol)

        raise ArgumentError.new "'type' argument cannot be empty" if type.is_a?(String) && type.empty?

        @type = type.to_sym.upcase
      end

      # JSON Serialization (Marshalling)
      def to_json(*ary)
        {
          json_class: self.class.name,
          data: as_json,
        }.to_json(*ary)
      end

      def ==(other)
        return false unless other.class == self.class

        @type == other.type
      end
      alias eql? ==
    end
  end
end
