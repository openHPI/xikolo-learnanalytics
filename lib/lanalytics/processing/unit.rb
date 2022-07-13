# frozen_string_literal: true

module Lanalytics
  module Processing
    class Unit
      extend Forwardable

      attr_accessor :type, :data

      def initialize(type, data)
        unless data.is_a?(Hash)
          raise ArgumentError.new 'Wrong type of data; Needs to be Hash'
        end

        @type = type
        @data = data.with_indifferent_access
      end

      def_delegator :@data, :[], :[]

      def inspect
        "Processing Unit of '#{@type}' type with following data: #{@data.inspect}"
      end
    end
  end
end
