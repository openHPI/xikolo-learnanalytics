module Lanalytics
  module Processing
    module Datasources
      class PostgresqlDatasource < Datasource
        attr_reader :dbname

        def initialize(postgres_config)
          super(postgres_config)
          init_with(postgres_config)
        end

        def init_with(postgres_config)
        
          # unless File.exists?(postgresdb_config_yml)
          #   raise ArgumentError.new("The settings file for this datasource not found under '#{postgresdb_config_yml}'")
          # end

          # postgresdb_config = YAML.load_file(postgresdb_config_yml).with_indifferent_access
          # postgresdb_config = postgresdb_config[Rails.env] || postgresdb_config

          @connection_pool = ConnectionPool.new(size: 1) { PG.connect(dbname: @dbname) }
          
          
          # This would be an alternative of initializing the connection
          # begin
          #   @conn = PG.connect(postgres_database_config)
          # rescue Exception => any_error
          #   Rails.logger.error "No Postgres connection could be created for database #{postgres_database_config[:db_name]} with following error message #{any_error.message}."
          #   # raise 'No Neo4j::Session could be created. Plz have a look at the configuration ...' unless session
          # end

        end

        def exec(&block)
          return unless block_given?          

          @connection_pool.with do | conn |
            yield conn
          end
        end

        def settings
          # Return all instance variables expect the instance variable 'connection_pool' 
          return self.instance_values.symbolize_keys.except(:connection_pool)
        end

      end
    end
  end
end

