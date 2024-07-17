# frozen_string_literal: true

module Lanalytics
  module Processing
    module Datasources
      class PostgresqlDatasource < Datasource
        attr_reader :database, :host, :port, :user, :password, :timeout

        def initialize(postgres_config)
          super(postgres_config)
          setup
        end

        def pool_size
          @pool.to_i # comes from postgres_config file
        end

        def setup
          @connection_pool = ConnectionPool.new(size: pool_size) do
            PG.connect(postgres_config)
          end
        end

        def ping
          PG::Connection.ping(postgres_config) == PG::Constants::PQPING_OK
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

        private

        def postgres_config
          {
            host:, port:,
            dbname: database,
            user:, password:,
            connect_timeout: timeout
          }.compact
        end
      end
    end
  end
end
