module Lanalytics
  module Metric
    class TopCountries < FallbackMetric

      alternative_metrics TopCountriesGa, TopCountriesEs

      process_result do |result|
        result.map do |item|
          item.slice :country_code, :country_code_iso3, :distinct_users
        end
      end

    end
  end
end