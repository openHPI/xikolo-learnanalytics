module Lanalytics
  module Processing
    module Datasources
      class Neo4jDatasource < Datasource
        attr_reader :db_type, :db_url

        def initialize(neo4j_config)
          super(neo4j_config)

          init_with(neo4j_config)
        end

        def init_with(neo4j_config)
          

          # neo4j_remaining_config = neo4j_config.except(:db_type, :db_url)
          
          # Register a default Neo4j::Session for this application
          # @session = Neo4j::Session.open(@db_type, @db_url, neo4j_config.except(:db_type, :db_url))
          @session = Neo4j::Session.open(@db_type.to_sym, @db_url)

          raise 'No Neo4j::Session could be created. Plz have a look at the configuration ...' unless @session
        end

        
        def exec(&block)
          return unless block_given?
          yield @session
        end

        def settings
          # Return all instance variables expect the instance variable 'session' 
          return self.instance_values.symbolize_keys.except(:session)
        end

      end
    end
  end
end

