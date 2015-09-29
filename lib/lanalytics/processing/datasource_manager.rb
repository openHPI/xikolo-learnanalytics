module Lanalytics
  module Processing
    class DatasourceManager
      include Singleton

      attr_reader :datasources

      def initialize
        @datasources = {}
      end

      def add_datasource(datasource)
        @datasources[datasource.key] = datasource
      end

      def self.add_datasource(datasource)
        instance.add_datasource(datasource)
      end

      def self.get_datasource(datasource_key)
        instance.datasources[datasource_key]
      end

      def self.datasource_exists?(datasource_key)
        instance.datasources.key?(datasource_key)
      end

      def self.new_datasource
        return unless block_given?

        datasource = yield

        unless datasource.is_a?(Lanalytics::Processing::Datasources::Datasource)
          fail ArgumentError, 'The block has to return a Datasource ...'
        end

        unless datasource.key
          fail ArgumentError, 'The returned Datasource has to contain a key'
        end

        instance.add_datasource(datasource)

        datasource
      end

      def self.setup_datasource(filename)
        datasource_config = YAML.load_file(filename).with_indifferent_access
        datasource_config = datasource_config[Rails.env] || datasource_config

        datasource_adapter = datasource_config[:datasource_adapter]

        unless datasource_adapter
          Rails.logger.warn "The datasource config '#{filename}' does not contain the required key 'datasource_adapter'"
          return
        end

        datasource_class = "Lanalytics::Processing::Datasources::#{datasource_adapter}".constantize
        datasource = datasource_class.new(datasource_config)

        Lanalytics::Processing::DatasourceManager.add_datasource(datasource)
        Rails.logger.info "The datasource config '#{filename}' loaded into DatasourceManager"
      end

    end
  end
end

