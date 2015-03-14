LANALYTICS_PIPELINE_FLIPPER_FILE = "#{Rails.root}/config/lanalytics_pipeline_flipper.yml"
lanalytics_pipeline_flipper_config = YAML.load_file(LANALYTICS_PIPELINE_FLIPPER_FILE).with_indifferent_access
lanalytics_pipeline_flipper_config = lanalytics_pipeline_flipper_config[Rails.env] || lanalytics_pipeline_flipper_config

# Load all datasources
# TODO:: Put this code inside the DatasourceManager as done with the PipelineManager
DATASOURCES_FOLDER = "#{Rails.root}/config/datasources"
datasources = lanalytics_pipeline_flipper_config.fetch(:datasources, [])
datasources ||= []
datasources.each do | datasource_yml_file |

  datasource_config = YAML.load_file("#{DATASOURCES_FOLDER}/#{datasource_yml_file}").with_indifferent_access
  datasource_config = datasource_config[Rails.env] || datasource_config

  unless datasource_adapter = datasource_config[:datasource_adapter]
    Rails.logger.warn "The datasource config '#{datasource_yml_file}' does not contain the required key 'datasource_adapter'"
    next
  end

  datasource_class = "Lanalytics::Processing::Datasources::#{datasource_adapter}".constantize
  datasource = datasource_class.new(datasource_config)

  Lanalytics::Processing::DatasourceManager.add_datasource(datasource)
  Rails.logger.info "The datasource config '#{datasource_yml_file}' loaded into DatasourceManager"
end

# Setup the pipelines
PIPELINES_FOLDER = "#{Rails.root}/lib/lanalytics/processing/pipelines"
pipelines = lanalytics_pipeline_flipper_config.fetch(:pipelines, [])
pipelines ||= []
pipelines.each do | pipelines_setup_file |
  Lanalytics::Processing::PipelineManager.setup_pipelines("#{PIPELINES_FOLDER}/#{pipelines_setup_file}")
end

