module Lanalytics
  module Processing
    module Transformer

      class GeoinfoFinder < TransformStep

        def transform(original_event, processing_units, load_commands, pipeline_ctx)
          processing_units.each do |processing_unit|
            next if processing_unit[:in_context].nil? || processing_unit[:in_context][:user_ip].nil?

            user_ip = processing_unit[:in_context][:user_ip]

            geoip_info = GeoIP.new('GeoLiteCity.dat').city(user_ip) || stubbed_geoinfo

            processing_unit[:in_context][:user_location_city]         = geoip_info[:city_name]
            processing_unit[:in_context][:user_location_country_code] = geoip_info[:country_code2]
            processing_unit[:in_context][:user_location_country_name] = geoip_info[:country_name]
            processing_unit[:in_context][:user_location_latitude]     = geoip_info[:latitude]
            processing_unit[:in_context][:user_location_longitude]    = geoip_info[:longitude]

            timezone = geoip_info[:timezone]
            unless timezone.nil?
              processing_unit[:in_context][:user_location_time_zone] = timezone
              processing_unit[:in_context][:user_local_timestamp]    = Time.now.in_time_zone(timezone).iso8601
            end
          end
        end

        # Since all events are also produced in development, stub the data
        def stubbed_geoinfo
          return nil unless Rails.env.development?

          {
            city_name: 'Localhost',
            country_code2: 'ZZ',
            country_name: 'Germany',
            latitude: 52.5167,
            longitude: 13.3833,
            timezone: 'Europe/Berlin'
          }
        end

      end

    end
  end
end
