module Lanalytics
  module Processing
    class DatasourceManager
      include Singleton

      def initialize
        @datasources = {}
      end

      def add_datasource(datasource)
        @datasources[datasource.key] = datasource
      end

      def self.add_datasource(datasource)
        self.instance.add_datasource(datasource)
      end

      def get_datasources
        return @datasources
      end

      def self.get_datasource(datasource_key)
        self.instance.get_datasources[datasource_key]
      end

      def self.datasource_exists?(datasource_key)
        self.instance.get_datasources.has_key?(datasource_key)
      end

      def self.new_datasource

        return unless block_given?

        datasource = yield

        raise ArgumentError.new "The block has to return a Datasource ..." unless datasource.is_a?(Lanalytics::Processing::Datasources::Datasource)
        raise ArgumentError.new "The returned Datasource has to contain a key" unless datasource.key

        self.instance.add_datasource(datasource)

        return datasource 

      end

    end
  end
end

