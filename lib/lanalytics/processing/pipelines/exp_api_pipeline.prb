
unless Lanalytics::Processing::DatasourceManager.datasource_exists?('exp_api_elastic')
  raise "Datasource 'exp_api_elastic' is not available."
end

pipeline_for("xikolo.web.exp_event.create", :exp_api, Lanalytics::Processing::ProcessingAction::CREATE) do
    
  datasource = Lanalytics::Processing::DatasourceManager.get_datasource('exp_api_elastic')

  extractor Lanalytics::Processing::Extractor::AmqEventExtractor.new(:exp_event)

  transformer Lanalytics::Processing::Transformer::AnonymousDataFilter.new
  transformer Lanalytics::Processing::Transformer::ExpApiSchemaTransformer.new
  
  loader Lanalytics::Processing::Loader::ElasticSearchLoader.new(datasource)
end
