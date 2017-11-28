require 'csv'

module Lanalytics
  module Processing
    module GoogleAnalytics
      class GeoIdLookup
        def initialize(location_criteria_file_path)
          @city_ids = {}
          CSV.foreach(location_criteria_file_path, :headers => true) do |row|
            next unless row['Target Type'] == 'City' and row['Status'] == 'Active'

            id = row['Criteria ID']
            country_code = row['Country Code']
            city_name = row['Name']
            if @city_ids[country_code].nil?
              @city_ids[country_code] = {}
            end
            @city_ids[country_code][city_name] = id
          end
        end

        def get(country_code, city_name)
          @city_ids.dig(country_code, city_name) || country_code
        end
      end
    end
  end
end
