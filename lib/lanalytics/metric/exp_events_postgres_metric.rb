# frozen_string_literal: true

module Lanalytics
  module Metric
    class ExpEventsPostgresMetric < Base
      def self.datasource_keys
        %w[exp_events_postgres]
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
