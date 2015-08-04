module Lanalytics
  module Processing
    module Transformer

      class GeolocationFinder < TransformStep

        def transform(original_event, processing_units, load_commands, pipeline_ctx)
          processing_units.each do | processing_unit |
            next if processing_unit[:in_context].nil?

            user_ip = processing_unit[:in_context][:user_ip]
            unless user_ip.nil?
              geoip_info = GeoIP.new('GeoLiteCity.dat').city(user_ip)
              next if geoip_info.nil?

              processing_unit[:in_context][:user_location_city] = geoip_info[:city_name]
              processing_unit[:in_context][:user_location_country_code] = geoip_info[:country_code2]
              processing_unit[:in_context][:user_location_country_name] = geoip_info[:country_name]
              processing_unit[:in_context][:user_location_latitude] = geoip_info[:latitude]
              processing_unit[:in_context][:user_location_longitude] = geoip_info[:longitude]
              processing_unit[:in_context][:user_location_time_zone] = geoip_info[:timezone]
            end
          end
        end

      end

    end
  end
end
