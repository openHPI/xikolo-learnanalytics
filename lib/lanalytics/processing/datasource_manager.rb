# frozen_string_literal: true

module Lanalytics
  module Processing
    class DatasourceManager
      include Singleton

      attr_reader :datasources

      def self.setup_datasource(filename)
        begin
          datasource_config = YAML.load_file(filename, aliases: true).with_indifferent_access
        rescue ArgumentError # Ruby 2.7 does not has aliases: keyword
          datasource_config = YAML.load_file(filename).with_indifferent_access
        end
        datasource_config = datasource_config[Rails.env] || datasource_config

        datasource_adapter = datasource_config[:datasource_adapter]

        unless datasource_adapter
          Rails.logger.warn "The datasource config '#{filename}' does not contain the required key 'datasource_adapter'"
          return
        end

        datasource_class = "Lanalytics::Processing::Datasources::#{datasource_adapter}".constantize
        datasource = datasource_class.new(datasource_config)

        Lanalytics::Processing::DatasourceManager.add_datasource(datasource)
        Rails.logger.debug { "The datasource config '#{filename}' loaded into DatasourceManager" }
      end

      def self.add_datasource(datasource)
        instance.add_datasource(datasource)
      end

      def self.datasource(datasource_key)
        instance.datasources[datasource_key]
      end

      def self.datasource_exists?(datasource_key)
        instance.datasources.key?(datasource_key)
      end

      def self.new_datasource
        return unless block_given?

        datasource = yield

        unless datasource.is_a?(Lanalytics::Processing::Datasources::Datasource)
          raise ArgumentError.new 'The block has to return a Datasource ...'
        end

        raise ArgumentError.new 'The returned Datasource has to contain a key' unless datasource.key

        instance.add_datasource(datasource)

        datasource
      end

      # ---------
      def initialize
        @datasources = {}
      end

      def add_datasource(datasource)
        @datasources[datasource.key] = datasource
      end
    end
  end
end
