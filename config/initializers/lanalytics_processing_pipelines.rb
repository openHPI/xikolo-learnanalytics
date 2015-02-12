
# Load all datasources
DATASOURCES_FOLDER = "#{Rails.root}/lib/lanalytics/processing/datasources"
Dir.glob("#{DATASOURCES_FOLDER}/*_datasource.yml") do | datasource_yml |

  datasource_config = YAML.load_file(datasource_yml).with_indifferent_access
  datasource_config = datasource_config[Rails.env] || datasource_config

  unless datasource_adapter = datasource_config[:datasource_adapter]
    Rails.logger.warn "The datasource config '#{datasource_yml}' does not contain the required key 'datasource_adapter'" 
    next
  end

  datasource_class = "Lanalytics::Processing::Datasources::#{datasource_adapter}".constantize
  datasource = datasource_class.new(datasource_config)

  Lanalytics::Processing::DatasourceManager.add_datasource(datasource)
end


# Setup the pipelines
PIPELINES_FOLDER = "#{Rails.root}/lib/lanalytics/processing/pipelines"
Lanalytics::Processing::PipelineManager.setup_pipelines(PIPELINES_FOLDER)
