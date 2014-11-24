module Lanalytics
  module Processing
    module LoadORM
      class UpdateCommand
        attr_reader :entity
        def self.with(entity)
          self.new(entity)
        end

        def initialize(entity)
          # Ensure not nil
          @entity = entity
        end
      end
    end
  end
end