# We do not want this initializer to be executed within a rake task
# See in http://stackoverflow.com/questions/7508170/rails-3-1-how-to-run-an-initializer-only-for-the-web-app-rails-server-unicorn
# And see in http://stackoverflow.com/questions/13506690/how-to-determine-if-rails-is-running-from-cli-console-or-as-server

if defined?(Rails::Server) and not Lanalytics.rake?

  Rails.application.config.after_initialize do

    # Delete all datasources 
    Datasource.delete_all

    datasources = Lanalytics::Processing::DatasourceManager.instance.get_datasources
    datasources.values.each do | datasource |
      datasource_settings = datasource.settings.except(:key, :name, :description)
      
      datasource_class_name = datasource.class.name.demodulize
      
      # If it is defined as an Active-Record Class ...
      if Object.const_defined?(datasource_class_name)
        datasource_activerecord_class = Object.const_get(datasource_class_name)
        datasource_ar_entity = datasource_activerecord_class.create(
          key: datasource.key, 
          name: datasource.name, 
          description: datasource.description, 
          settings: datasource_settings
        )
        puts datasource_ar_entity.inspect
        next
      end

      Datasource.create(
        key: datasource.key, 
        name: datasource.name, 
        description: datasource.description, 
        settings: datasource_settings,
        type: datasource_class_name
      )
    end
  end

end