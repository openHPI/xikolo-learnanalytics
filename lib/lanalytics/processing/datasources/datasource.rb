module Lanalytics
  module Processing
    module Datasources
      
      class Datasource
        attr_reader :key, :name, :description
        
        def initialize args
          args.each do |k,v|
            instance_variable_set("@#{k}", v) unless v.nil?
          end
        end

        def name
          
          return key unless @name

          return @name
        end

      end

    end
  end
end

