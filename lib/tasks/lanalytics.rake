require 'link_header'

namespace :lanalytics do
  
  desc "Loads all lanalytics data initially"
  task :sync, [:allowed_processing_keys] => :environment do | task, args |

    args.allowed_processing_keys = args.allowed_processing_keys.split(' ').map! { | processing_key | processing_keys.strip } if args.allowed_processing_keys

    old_logger_level = Rails.logger.level
    Rails.logger.level = 1 # :info

    service_urls = YAML.load_file("#{Rails.root}/config/services.yml")
    service_urls = (service_urls[Rails.env] || service_urls)['services']

    processings = YAML.load_file("#{Rails.root}/config/processing.yml")

    processings.each do | processing_key, entity_json_route |
      
      next unless processing_key.end_with?('.url')

      # If processing keys are given, then we look if the current processing should be handled
      next if args.allowed_processing_keys and not args.allowed_processing_keys.include?(processing_key)

      # Find out the base url for the service
      service_name = /^xikolo\.(?<service_name>\w+)\.\w+\.url$/.match(processing_key.to_s)[:service_name].to_s
      unless service_urls.has_key?(service_name)
        Rails.logger.info "Service '#{service_name}' not defined in service.yml"
        next
      end
      service_base_url = service_urls[service_name]
      json_url = "#{service_base_url}#{entity_json_route}"

      # Replacing '.url' of processing_definition_key with '.create'
      processing_steps = processings["#{processing_key[0...-4]}.create"]
      unless processing_steps
        logger.info "'#{processing_key[0...-4]}.create' in processing.yml but needed in order to process the resources"
        next
      end

      processing_steps.map! do | processing_step |
        # Some processing steps are not loaded during 'YAML.load_file'; that's why we are evaluating this in ruby
        processing_step = eval(processing_step) if processing_step.is_a?(String)
        processing_step
      end

      Lanalytics::Processing::RestProcessing.process(json_url, processing_steps)
    end

    Rails.logger.level = old_logger_level
  end
end
