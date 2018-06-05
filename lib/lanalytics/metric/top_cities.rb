module Lanalytics
  module Metric
    class TopCities < FallbackMetric

      alternative_metrics TopCitiesGa, TopCitiesEs

      process_result do |result|
        result.map do |item|
          item.slice :city_name, :country_code, :country_code_iso3, :distinct_users, :relative_users
        end
      end

    end
  end
end