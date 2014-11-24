module Lanalytics
  module Processing
    class Unit
      extend Forwardable

      attr_accessor :type, :data

      def initialize(type, data)

        raise ArgumentError.new('Wrong type of data; Needs to be Hash') unless data.is_a?(Hash)
        @type, @data = type, data.with_indifferent_access
      end

      def_delegator :@data, :[], :[]

      def inspect
        return "Processing Unit of '#{@type}' type with following data: #{@data.inspect}"
      end
    end
  end
end