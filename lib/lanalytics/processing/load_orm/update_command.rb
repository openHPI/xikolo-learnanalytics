# frozen_string_literal: true

module Lanalytics
  module Processing
    module LoadORM
      class UpdateCommand
        attr_reader :entity

        def self.with(entity)
          new(entity)
        end

        def initialize(entity)
          # Ensure not nil
          @entity = entity
        end
      end
    end
  end
end
