require 'link_header'

namespace :lanalytics do
  
  desc "Loads all lanalytics data initially"
  task :sync, [:allowed_processing_keys] => :environment do | task, args |

    args.allowed_processing_keys = args.allowed_processing_keys.split(' ').map! { | processing_key | processing_key.strip } if args.allowed_processing_keys

    old_logger_level = Rails.logger.level
    Rails.logger.level = 1 # :info

    service_urls = YAML.load_file("#{Rails.root}/config/services.yml")
    service_urls = (service_urls[Rails.env] || service_urls)['services']

    processings = YAML.load_file("#{Rails.root}/config/lanalytics_sync.yml")

    processings.each do | pipeline_name, entity_json_route |
      
      # If processing keys are given, then we look if the current processing should be handled
      next if args.allowed_processing_keys and not args.allowed_processing_keys.include?(pipeline_name)

      # Find out the base url for the service
      service_name = /^xikolo\.(?<service_name>\w+)\.\w+\.create$/.match(pipeline_name.to_s)[:service_name].to_s
      unless service_urls.has_key?(service_name)
        Rails.logger.info "Service '#{service_name}' not defined in service.yml"
        next
      end

      service_base_url = service_urls[service_name]
      json_url = "#{service_base_url}#{entity_json_route}"

      # Replacing '.url' of processing_definition_key with '.create'
      # processing_steps = processings["#{processing_key[0...-4]}.create"]
      # unless processing_steps
      #   logger.info "'#{processing_key[0...-4]}.create' in processing.yml but needed in order to process the resources"
      #   next
      # end

      Lanalytics::Processing::RestPipeline.process(json_url, pipeline_name)
    end

    Rails.logger.level = old_logger_level
  end
end
