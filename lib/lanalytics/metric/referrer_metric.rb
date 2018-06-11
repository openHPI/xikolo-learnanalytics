module Lanalytics
  module Metric
    class ReferrerMetric < Base

      def self.datasource_keys
        %w(referral)
      end

      def self.datasource
        datasources.first
      end

    end
  end
end
