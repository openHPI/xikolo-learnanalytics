module Lanalytics
  module Processing
    module Datasources

      # Responsible for handling the connections
      class Datasource
        attr_reader :key, :name, :description

        def initialize(args)
          args.each do |k, v|
            instance_variable_set("@#{k}", v) unless v.nil?
          end
        end

        def name
          return key unless @name

          @name
        end

        # Datasource specific methods
        def exec(&block)
          fail NotImplementedError, 'This method has to be implemented in the subclass!'
        end

        def settings
          fail NotImplementedError, 'This method has to be implemented in the subclass!'
        end
      end

    end
  end
end

