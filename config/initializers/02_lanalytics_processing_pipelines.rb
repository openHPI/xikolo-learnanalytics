# run before integration initializers

# needed for autoloading constants in development
require 'lanalytics/processing/datasource_manager'
require 'lanalytics/processing/pipeline_manager'
require 'lanalytics/processing/batching_queue'
require 'lanalytics/processing/google_analytics/hits_emitter'
require 'lanalytics/processing/google_analytics/geo_id_lookup'

LANALYTICS_PIPELINE_FLIPPER_FILE = "#{Rails.root}/config/lanalytics_pipeline_flipper.yml"
flipper_config = YAML.load_file(LANALYTICS_PIPELINE_FLIPPER_FILE).with_indifferent_access
flipper_config = flipper_config[Rails.env] || flipper_config

# Load all datasources
DATASOURCES_FOLDER = "#{Rails.root}/config/datasources"
datasources = flipper_config.fetch(:datasources, [])
datasources ||= []
datasources.each do |datasource_yml_file|
  Lanalytics::Processing::DatasourceManager.setup_datasource("#{DATASOURCES_FOLDER}/#{datasource_yml_file}")
end

# Setup the pipelines
PIPELINES_FOLDER = "#{Rails.root}/lib/lanalytics/processing/pipelines"
pipelines = flipper_config.fetch(:pipelines, [])
pipelines ||= []
pipelines.each do |pipelines_setup_file|
  Lanalytics::Processing::PipelineManager.setup_pipelines("#{PIPELINES_FOLDER}/#{pipelines_setup_file}")
end
