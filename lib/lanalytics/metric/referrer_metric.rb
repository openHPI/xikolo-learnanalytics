module Lanalytics
  module Metric
    class ReferrerMetric < Base

      def self.datasource
        Lanalytics::Processing::DatasourceManager.datasource(datasource_name)
      end

      def self.datasource_name
        'referral'
      end

    end
  end
end
