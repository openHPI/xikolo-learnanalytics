# frozen_string_literal: true

require 'typhoeus/adapters/faraday'
module Lanalytics
  module Processing
    module Datasources
      class ElasticDatasource < Datasource
        attr_reader :host, :port, :client, :index

        def initialize(elastic_config)
          super(elastic_config)
          setup
        end

        def setup
          non_elasticsearch_opts = %i[client name key description index]
          config = instance_values.symbolize_keys.except(*non_elasticsearch_opts)

          @client = Elasticsearch::Client.new config

          return if @client

          raise 'No Elasticsearch::Client could be created. Plz have a look at the configuration ...'
        end

        def exec
          return unless block_given?

          yield @client
        end

        def ping
          @client.ping
        rescue Elasticsearch::Transport::Transport::ServerError
          false
        end

        def settings
          # Return all instance variables except the instance variable 'client'
          instance_values.symbolize_keys.except(:client)
        end
      end
    end
  end
end
