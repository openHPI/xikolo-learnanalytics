module Lanalytics
  module Metric
    class ExpApiPostgresMetric < Base

      def self.datasource_keys
        %w(exp_api_native)
      end

      def self.datasource
        datasources.first
      end

      def self.perform_query(query)
        loader = Lanalytics::Processing::Loader::PostgresLoader.new(datasource)
        loader.execute_sql(query)
      end

    end
  end
end
