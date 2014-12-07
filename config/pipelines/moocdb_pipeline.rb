
def moocdb_pipeline(processing_action, event_domain_ns_type, event_domain_type)
  
  pipeline_for("xikolo.#{event_domain_ns_type.downcase}.#{event_domain_type.downcase}.#{processing_action.to_s.downcase}", :mooc_db, processing_action) do
    extractor Lanalytics::Processing::Extractor::AmqEventExtractor.new(event_domain_type)

    transformer Lanalytics::Processing::Transformer::AnonymousDataFilter.new
    transformer Lanalytics::Processing::Transformer::MoocdbDataTransformer.new
    
    loader Lanalytics::Processing::Loader::PostgresLoader.new
    # loader Lanalytics::Processing::Loader::Neo4jLoader.new(:moocdb_neo)
  end

end

# MOOCdb Pipelines for 'CREATE', 'UPDATE' und 'DESTROY'
def moocdb_pipelines_for_crud(event_domain_ns_type, event_domain_type)
  
  moocdb_pipeline(Lanalytics::Processing::ProcessingAction::CREATE, event_domain_ns_type, event_domain_type)
  moocdb_pipeline(Lanalytics::Processing::ProcessingAction::UPDATE, event_domain_ns_type, event_domain_type)
  moocdb_pipeline(Lanalytics::Processing::ProcessingAction::DESTROY, event_domain_ns_type, event_domain_type)
end

create_action = Lanalytics::Processing::ProcessingAction::CREATE
update_action = Lanalytics::Processing::ProcessingAction::UPDATE
destroy_action = Lanalytics::Processing::ProcessingAction::DESTROY


# ------------------- User Domain Entities -------------------
moocdb_pipelines_for_crud(:account, :user)

# ------------------- Course Domain Entities -------------------
moocdb_pipelines_for_crud(:course, :course)
moocdb_pipelines_for_crud(:course, :item)
moocdb_pipeline(create_action, :course, :enrollment)
moocdb_pipeline(destroy_action, :course, :enrollment)


# ------------------- Submission Domain Entities -------------------
moocdb_pipeline(create_action, :submission, :submission)

# ------------------- Learning Room Domain Entities -------------------
# moocdb_pipelines_for_crud(:learning_room, :learning_room)
# moocdb_pipeline(create_action, :learning_room, :membership)
# moocdb_pipeline(destroy_action, :learning_room, :membership)

# ------------------- Pinboard Domain Entities -------------------
moocdb_pipeline(create_action, :pinboard, :question)
moocdb_pipeline(update_action, :pinboard, :question)
# moocdb_pipeline(create_action, :pinboard, :subscription)
# moocdb_pipeline(destroy_action, :pinboard, :subscription)
moocdb_pipeline(create_action, :pinboard, :answer)
moocdb_pipeline(update_action, :pinboard, :answer)
moocdb_pipeline(create_action, :pinboard, :comment)
moocdb_pipeline(update_action, :pinboard, :comment)


moocdb_pipeline(create_action, :web, :exp_event)