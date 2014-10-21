require 'link_header'

namespace :lanalytics do
  
  desc "Loads all lanalytics data initially"
  task sync: :environment do

    lanalytics_datasources = [
      
      Lanalytics::Datasource.new(:COURSE, 'http://localhost:3300/courses.json', [
        Lanalytics::Filter::CourseDataFilter.new
      ], [
        # Lanalytics::Processor::LoggerProcessor.new,
        Lanalytics::Processor::Neo4jProcessor.new
      ]),
      
      Lanalytics::Datasource.new(:ITEM, 'http://localhost:3300/items.json', [
        Lanalytics::Filter::ItemDataFilter.new
      ], [
        # Lanalytics::Processor::LoggerProcessor.new,
        Lanalytics::Processor::Neo4jProcessor.new
      ]),

      Lanalytics::Datasource.new(nil, 'http://localhost:3300/enrollments.json', [
        Lanalytics::Filter::EnrollmentDataFilter.new
      ], [
        Lanalytics::Processor::Neo4jProcessor.new
      ]),

      Lanalytics::Datasource.new(:USER, 'http://localhost:3100/users.json', [
        Lanalytics::Filter::UserDataFilter.new,
        Lanalytics::Filter::AnonymousDataFilter.new
      ], [
        # Lanalytics::Processor::LoggerProcessor.new,
        Lanalytics::Processor::Neo4jProcessor.new
      ])
    ]

    lanalytics_datasources.each do | lanalytics_datasource |
      
      progress_bar = ProgressBar.create(title: "Syncing from #{lanalytics_datasource.url}", format: '%p%% %t (%c/%C) |%b>>%i| %a', starting_at: 0, total: nil)
      datasource_partial_url = lanalytics_datasource.url

      first_round = true
      begin
        begin
          ressource_type = lanalytics_datasource.type
          response = RestClient.get(datasource_partial_url)
          resources_hash = MultiJson.load(response, symbolize_keys: true)
        rescue Exception => any_error
          puts "Lanalytics Datasource on url (#{lanalytics_datasource.url}) could not be processed and failed with the following error:"
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
          lanalytics_datasource.process(resource_hash)
          progress_bar.increment unless progress_bar.finished?
        end

        link_header_next_link = link_header.find_link(['rel', 'next'])
        datasource_partial_url = link_header_next_link ? link_header_next_link.href : nil

      end while datasource_partial_url
    end
  end
end
