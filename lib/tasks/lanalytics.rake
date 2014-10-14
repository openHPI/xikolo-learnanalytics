namespace :lanalytics do
  
  desc "Loads all lanalytics data initially"
  task sync: :environment do

    lanalytics_datasources = [
      Lanalytics::Datasource.new(:COURSE, 'http://localhost:3300/courses.json', [
        Lanalytics::Filter::CourseDataFilter.new
      ], [
        Lanalytics::Processor::LoggerProcessor.new,
        Lanalytics::Processor::Neo4jProcessor.new,
      ]),
      Lanalytics::Datasource.new(:ITEM, 'http://localhost:3300/items.json', [
        Lanalytics::Filter::ItemDataFilter.new
      ], [
        Lanalytics::Processor::LoggerProcessor.new,
        Lanalytics::Processor::Neo4jProcessor.new,
      ])

    ]

    lanalytics_datasources.each do | lanalytics_datasource |
      
      begin
        ressource_type = lanalytics_datasource.type
        response = RestClient.get(lanalytics_datasource.url)
        resources_hash = MultiJson.load(response, symbolize_keys: true)
      rescue Exception => any_error
        puts "Lanalytics Datasource on url (#{lanalytics_datasource.url}) could not be processed and failed with the following error:"
        puts any_error
        next
      end

      resources_hash.each do | resource_hash |
        lanalytics_datasource.process(resource_hash)
      end

        # lanalytics_datasource.finish

      # response = response.to_s.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
      # RestClient.get(lanalytics_datasource.url).each do | resource_hash |
      #   puts "#{ressource_hash}"
      # end
    end
  end

end
