require 'link_header'

namespace :lanalytics do
  
  desc "Loads all lanalytics data initially"
  task sync: :environment do

    old_logger_level = Rails.logger.level
    Rails.logger.level = 1 # :info

    processing_definitions = YAML.load_file("#{Rails.root}/config/processing.yml")

    processing_definitions.each do | processing_definition_key, service_url |
      next unless processing_definition_key.end_with?('.url')

      # Replacing '.url' of processing_definition_key with '.create'
      processing_steps = processing_definitions["#{processing_definition_key[0...-4]}.create"]
      unless processing_steps
        logger.info "'#{processing_definition_key[0...-4]}.create' in processing.yml but needed in order to process the resources"
        next
      end
      
      processing_steps.map! do | processing_step |
        # Some processing steps are not loaded during 'YAML.load_file'; that's why we are evaluating this in ruby
        processing_step = eval(processing_step) if processing_step.is_a?(String)
        processing_step
      end
      
      processing_chain_for_url = Lanalytics::Processing::ProcessingChain.new(processing_steps)

      progress_bar = ProgressBar.create(title: "Syncing from #{service_url}", format: '%p%% %t (%c/%C) |%b>>%i| %a', starting_at: 0, total: nil)
      datasource_partial_url = service_url

      first_round = true
      begin
        begin
          response = RestClient.get(datasource_partial_url)
          resources_hash = MultiJson.load(response, symbolize_keys: true)
        rescue Exception => any_error
          puts "Lanalytics Datasource on url (#{service_url}) could not be processed and failed with the following error:\033[K"
          puts "#{any_error.message[0..100]}..."
          break
        end

        link_header = LinkHeader.parse(response.headers[:link])

        # In the first round
        if first_round
          last_datasource_url_page_url = link_header.find_link(['rel', 'last']).href
          last_page_index = /.*?page=(?<page_index>.+).*/.match(last_datasource_url_page_url)[:page_index].to_i
          if last_page_index == 1
            total_item_count = resources_hash.length
          else
            total_item_count = (last_page_index-1) * resources_hash.length
          end
          progress_bar.total = total_item_count
          first_round = false
        end

        resources_hash.each do | resource_hash |
          processing_chain_for_url.process(resource_hash, { processing_action: Lanalytics::Processing::ProcessingAction::CREATE })
          progress_bar.increment unless progress_bar.finished?
        end

        link_header_next_link = link_header.find_link(['rel', 'next'])
        datasource_partial_url = link_header_next_link ? link_header_next_link.href : nil

      end while datasource_partial_url
    end

    Rails.logger.level = old_logger_level
  end
end
