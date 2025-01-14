# frozen_string_literal: true

#
# Set up lanalytics pipeline and reload on code changes
#
Rails.application.config.to_prepare do
  flipper_file = Rails.root.join('config/lanalytics_pipeline_flipper.yml')
  flipper_config = YAML.load_file(flipper_file, aliases: true).with_indifferent_access
  flipper_config = flipper_config[Rails.env] || flipper_config

  # Load all datasources
  datasource_folder = Rails.root.join('config/datasources')
  datasources = flipper_config.fetch(:datasources, [])
  datasources ||= []
  datasources.each do |datasource_yml_file|
    Lanalytics::Processing::DatasourceManager.setup_datasource(datasource_folder.join(datasource_yml_file))
  end

  # Setup the pipelines
  pipelines_folder = Rails.root.join('lib/lanalytics/processing/pipelines')
  pipelines = flipper_config.fetch(:pipelines, [])
  pipelines ||= []
  pipelines.each do |pipelines_setup_file|
    Lanalytics::Processing::PipelineManager.setup_pipelines(pipelines_folder.join(pipelines_setup_file))
  end
end
