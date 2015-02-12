module Lanalytics
  module Processing
    module Datasources
      class ElasticDatasource < Datasource

        attr_reader :host, :port, :client, :index

        def initialize(elastic_config)
          super(elastic_config)
          init_with(elastic_config)
        end

        def init_with(elastic_config)

          @client = Elasticsearch::Client.new host: @host, port: @port

          raise 'No Neo4j::Session could be created. Plz have a look at the configuration ...' unless @client
        end

        def exec
          return unless block_given?
          yield @client
        end

        def settings
          # Return all instance variables expect the instance variable 'client' 
          return self.instance_values.symbolize_keys.except(:client)
        end
      end
    end
  end
end

