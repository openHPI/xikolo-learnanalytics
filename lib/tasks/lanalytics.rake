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
      
      begin
        ressource_type = lanalytics_datasource.type
        response = RestClient.get(lanalytics_datasource.url)
        resources_hash = MultiJson.load(response, symbolize_keys: true)
      rescue Exception => any_error
        puts "Lanalytics Datasource on url (#{lanalytics_datasource.url}) could not be processed and failed with the following error:"
        puts "#{any_error.message[0..100]}..."
        next
      end

      progress_bar = ProgressBar.create(:title => "Syncing from #{lanalytics_datasource.url}:", :format => '%p%% %t |%b>>%i| %a', :starting_at => 0, :total => resources_hash.length)
      resources_hash.each do | resource_hash |
        lanalytics_datasource.process(resource_hash)
        progress_bar.increment
      end

        # lanalytics_datasource.finish

      # response = response.to_s.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
      # RestClient.get(lanalytics_datasource.url).each do | resource_hash |
      #   puts "#{ressource_hash}"
      # end
    end
  end

end
