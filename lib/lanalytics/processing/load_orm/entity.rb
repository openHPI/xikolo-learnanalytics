# frozen_string_literal: true

module Lanalytics
  module Processing
    module LoadORM
      class Entity
        include Lanalytics::Helper::HashHelper

        attr_reader :entity_key, :primary_attribute, :attributes

        # factory method
        def self.create(entity_key, &block)
          entity = new(entity_key)
          entity.instance_eval(&block)

          entity
        end

        def initialize(entity_key, attributes = [])
          # Ensure not nil
          unless entity_key && entity_key.is_a?(Symbol)
            raise ArgumentError.new 'Entity_key has to be a Symbol'
          end

          @entity_key = entity_key
          @attributes = attributes
        end

        def with_primary_attribute(name, data_type = :uuid, value = nil)
          @primary_attribute = PrimaryAttribute.new(name, data_type, value)
        end

        def with_attribute(name, data_type, value = nil)
          @attributes << Attribute.new(name, data_type, value)
        end

        def all_non_nil_attributes
          all_non_nil_attributes = @attributes.reject {|attr| attr.value.nil? }
          all_non_nil_attributes.unshift(@primary_attribute) if @primary_attribute

          all_non_nil_attributes
        end

        def all_attribute_names
          all_non_nil_attributes.collect(&:name)
        end

        def all_attribute_values
          all_non_nil_attributes.collect(&:value)
        end

        def [](name)
          @attributes.find {|a| a.name == name }
        end
      end

      class Attribute
        attr_reader :name, :data_type, :value

        def initialize(name, data_type, value = nil)
          @name = name
          @data_type = data_type
          @value = value
        end

        def inspect
          "Attribute '#{@name}' of type '#{@data_type}' with value: #{@value}"
        end
      end

      class PrimaryAttribute < Attribute
        def initialize(name, data_type, value)
          if value.nil? || (value.is_a?(String) && value.empty?)
            raise ArgumentError.new 'value cannot be nil or blank'
          end

          super
        end

        def inspect
          "Primary #{super.inspect}"
        end
      end
    end
  end
end
