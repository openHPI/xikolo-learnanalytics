require 'json'

module Lanalytics
  module Model
    class StmtComponent
      attr_reader :type

      def initialize(type)
        unless type.is_a?(String) || type.is_a?(Symbol)
          fail ArgumentError, "'type' argument cannot be nil"
        end

        if type.is_a?(String) && type.empty?
          fail ArgumentError, "'type' argument cannot be empty"
        end

        @type = type.to_sym.upcase
      end

      # JSON Serialization (Marshalling)
      def to_json(*a)
        {
          json_class: self.class.name,
          data: as_json
        }.to_json(*a)
      end

      def ==(other)
        return false unless other.class == self.class

        @type == other.type
      end
      alias_method :eql?, :==

    end
  end
end
