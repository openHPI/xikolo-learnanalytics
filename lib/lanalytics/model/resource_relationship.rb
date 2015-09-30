module Lanalytics
  module Model
    class ResourceRelationship
      attr_reader :from_resource, :type, :properties, :to_resource

      def initialize(from_resource, type, to_resource, properties = {})
        @from_resource = from_resource

        @type = type

        @to_resource = to_resource

        properties ||= {}
        @properties = properties
      end
    end
  end
end
