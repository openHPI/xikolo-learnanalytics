
def moocdb_pipeline(processing_action, event_domain_ns_type, event_domain_type)
  
  pipeline_for("xikolo.#{event_domain_ns_type.downcase}.#{event_domain_type.downcase}.create", :mooc_db, processing_action) do
    extractor Lanalytics::Processing::Extractor::AmqEventExtractor.new(event_domain_type)

    transformer Lanalytics::Processing::Transformer::AnonymousDataFilter.new
    transformer Lanalytics::Processing::Transformer::MoocdbDataTransformer.new
    
    loader Lanalytics::Processing::Loader::PostgresLoader.new
    # loader Lanalytics::Processing::Loader::Neo4jLoader.new(:moocdb_neo)
  end

end

create_action = Lanalytics::Processing::ProcessingAction::CREATE

moocdb_pipeline(create_action, :account, :user)
moocdb_pipeline(create_action, :course, :course)
# moocdb_pipeline(create_action, :course, :item)
moocdb_pipeline(create_action, :course, :enrollment)