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
          non_elasticsearch_opts = [:client, :name, :key, :description, :index]
          config = instance_values.symbolize_keys.reject { |k, v| non_elasticsearch_opts.include? k }

          @client = Elasticsearch::Client.new config

          unless @client
            fail 'No Elasticsearch::Client could be created. Plz have a look at the configuration ...'
          end
        end

        def exec
          return unless block_given?
          yield @client
        end

        def settings
          # Return all instance variables except the instance variable 'client'
          instance_values.symbolize_keys.except(:client)
        end
      end
    end
  end
end

