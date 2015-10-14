module Lanalytics
  module Processing
    module Datasources
      class PostgresqlDatasource < Datasource
        attr_reader :database, :host, :port, :user, :password, :timeout

        def initialize(postgres_config)
          super(postgres_config)
          init_with(postgres_config)
        end

        def pool_size
          @pool.to_i  # comes from postgres_config file
        end

        def init_with(postgres_config)
          pool_size = 1

          opts = {
            host: host, port: port,
            dbname: database,
            user: user, password: password,
            connect_timeout: timeout
          }.reject{ |k, v| v.nil? }

          @connection_pool = ConnectionPool.new(size: pool_size) do
            PG.connect(opts)
          end

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

          @connection_pool.with do |conn|
            yield conn
          end
        end

        def settings
          # Return all instance variables except the instance variable 'connection_pool'
          instance_values.symbolize_keys.except(:connection_pool)
        end

      end
    end
  end
end

