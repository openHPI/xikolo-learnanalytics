
unless Lanalytics::Processing::DatasourceManager.datasource_exists?('exp_api_elastic')
  fail "Datasource 'exp_api_elastic' is not available."
end

def create_exp_pipeline(route, extractor_type, action)
  processing_action = case action
  when :create then Lanalytics::Processing::ProcessingAction::CREATE
  when :update then Lanalytics::Processing::ProcessingAction::UPDATE
  when :destroy then Lanalytics::Processing::ProcessingAction::DESTROY
  end

  pipeline_for(route, :exp_api, processing_action) do
    datasource = Lanalytics::Processing::DatasourceManager.get_datasource('exp_api_elastic')

    extractor Lanalytics::Processing::Extractor::AmqEventExtractor.new(extractor_type)

    transformer Lanalytics::Processing::Transformer::AnonymousDataFilter.new
    transformer Lanalytics::Processing::Transformer::ExpApiSchemaTransformer.new

    loader Lanalytics::Processing::Loader::ElasticSearchLoader.new(datasource)
  end
end

create_exp_pipeline('xikolo.web.exp_event.create', :exp_event, :create)
create_exp_pipeline('xikolo.pinboard.question.create', :question, :create)
create_exp_pipeline('xikolo.pinboard.answer.create', :answer, :create)
create_exp_pipeline('xikolo.pinboard.comment.create', :comment, :create)
create_exp_pipeline('xikolo.pinboard.watch.create', :watch, :create)
create_exp_pipeline('xikolo.pinboard.watch.update', :watch, :create)
create_exp_pipeline('xikolo.course.visit.create', :visit, :create)
