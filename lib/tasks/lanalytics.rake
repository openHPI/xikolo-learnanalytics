require 'link_header'

namespace :lanalytics do

  desc 'Loads all lanalytics data initially'
  task :sync, [:schema, :allowed_pipeline_names] => [:environment] do |_, args|
    # Making sure that the Msgr.Client is shutdown
    Msgr.client.stop if Msgr.client.running?

    Rails.logger.info 'Performing lanalytics:sync'

    # Process inputs params
    args.with_defaults(:schema => nil, :allowed_pipeline_names => nil)

    schema = args.schema
    if schema
      schema = schema.strip
      Rails.logger.info "Only for specific schema: #{schema}"
    end

    allowed_pipeline_names = args.allowed_pipeline_names
    if allowed_pipeline_names
      allowed_pipeline_names = allowed_pipeline_names.split(' ').map! { |pipeline_name| pipeline_name.strip }
      Rails.logger.info "Only for the following pipelines: #{allowed_pipeline_names}" unless allowed_pipeline_names.empty?
    end

    service_urls = YAML.load_file("#{Rails.root}/config/services.yml")
    service_urls = (service_urls[Rails.env] || service_urls)['services']

    processings = YAML.load_file("#{Rails.root}/config/lanalytics_sync.yml")

    processings.each do |pipeline_name, entity_json_route|
      # If processing keys are given, then we look if the current processing should be handled
      next if allowed_pipeline_names and not allowed_pipeline_names.include?(pipeline_name)
      # Find out the base url for the service
      service_name = /^xikolo\.(?<service_name>\w+)\.\w+\.create$/.match(pipeline_name.to_s)[:service_name].to_s
      unless service_urls.has_key?(service_name)
        Rails.logger.info "Service '#{service_name}' not defined in service.yml"
        next
      end

      service_base_url = service_urls[service_name]
      json_url = "#{service_base_url}#{entity_json_route}"

      create_action = Lanalytics::Processing::Action::CREATE
      schema_pipelines = Lanalytics::Processing::PipelineManager.instance
        .find_piplines(schema, create_action, pipeline_name)
      if schema_pipelines.empty?
        Rails.logger.info "No pipelines found for name '#{pipeline_name}'" + (schema ? "in schema #{schema}" : '')
      end

      Lanalytics::Processing::RestPipeline.process(json_url, schema_pipelines)
    end
  end

  # In case we want to profile the whole thing
  task :sync_prof, [:schema, :allowed_pipeline_names] => [:environment] do |_, args|
    require 'ruby-prof'

    result = RubyProf.profile do
      Rake::Task['lanalytics:sync'].execute(args)
    end

    printer = RubyProf::FlatPrinter.new(result)
    printer.print(STDOUT, :min_percent => 2)
    printer = RubyProf::MultiPrinter.new(result)
    printer.print(:path => './tmp/profiling', :profile => 'profile')
  end

  desc 'Create custom dimensions and metrics for the configured Google Analytics account'
  task sync_ga_custom_definitions: :environment do
    datasource = Lanalytics::Processing::DatasourceManager.datasource('google_analytics')
    if datasource.nil?
      Rails.logger.info 'GoogleAnalyticsDatasource is not configured'
      next
    end

    datasource.sync_custom_definitions
  end

end
