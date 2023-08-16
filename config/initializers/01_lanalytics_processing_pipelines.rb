# frozen_string_literal: true

# run before integration initializers

# needed for autoloading constants in development
require 'lanalytics/processing/datasource_manager'
require 'lanalytics/processing/pipeline_manager'

LANALYTICS_PIPELINE_FLIPPER_FILE = "#{Rails.root}/config/lanalytics_pipeline_flipper.yml"
begin
  flipper_config = YAML.load_file(LANALYTICS_PIPELINE_FLIPPER_FILE, aliases: true).with_indifferent_access
rescue ArgumentError # Ruby 2.7 does not has aliases: keyword
  flipper_config = YAML.load_file(LANALYTICS_PIPELINE_FLIPPER_FILE).with_indifferent_access
end
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
