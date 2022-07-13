module Lanalytics
  module Processing
    module Transformer
      class GeoinfoFinder < TransformStep
        def transform(original_event, processing_units, load_commands, pipeline_ctx)
          processing_units.each do |processing_unit|
            next if processing_unit[:in_context].nil? || processing_unit[:in_context][:user_ip].nil?

            user_ip = processing_unit[:in_context][:user_ip]
            geoip_info = Lanalytics::Processing::GeoIp.lookup(user_ip)

            next unless geoip_info.found?

            processing_unit[:in_context][:user_location_city]         = geoip_info.city.name
            processing_unit[:in_context][:user_location_country_code] = geoip_info.country.iso_code
            processing_unit[:in_context][:user_location_country_name] = geoip_info.country.name
            processing_unit[:in_context][:user_location_latitude]     = geoip_info.location.latitude
            processing_unit[:in_context][:user_location_longitude]    = geoip_info.location.longitude

            timezone = geoip_info.location.time_zone
            unless timezone.nil?
              processing_unit[:in_context][:user_location_time_zone] = timezone
              processing_unit[:in_context][:user_local_timestamp]    = Time.now.in_time_zone(timezone).iso8601
            end
          end
        end
      end
    end
  end
end
