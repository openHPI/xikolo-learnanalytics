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

    end
  end
end

