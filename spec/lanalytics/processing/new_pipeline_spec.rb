require 'rails_helper'

describe Lanalytics::Processing::Pipeline, pending: true do

  it "bla" do

    data = FactoryGirl.attributes_for(:amqp_user)
    pipeline = Lanalytics::Processing::Pipeline.new('moocdb_user_create', Lanalytics::Processing::ProcessingAction::CREATE,
      [ Lanalytics::Processing::Extractor::AmqEventExtractor.new(:USER) ],
      [ Lanalytics::Processing::Transformer::AnonymousDataFilter.new, Lanalytics::Processing::Transformer::MoocdbDataTransformer.new ],
      [ Lanalytics::Processing::Loader::PostgresLoader.new, Lanalytics::Processing::Loader::Neo4jLoader.new ])
    pipeline.process(data)


    data = FactoryGirl.attributes_for(:amqp_course)
    pipeline = Lanalytics::Processing::Pipeline.new('moocdb_course_create', Lanalytics::Processing::ProcessingAction::CREATE,
      [ Lanalytics::Processing::Extractor::AmqEventExtractor.new(:COURSE) ],
      [ Lanalytics::Processing::Transformer::AnonymousDataFilter.new, Lanalytics::Processing::Transformer::MoocdbDataTransformer.new ],
      [ Lanalytics::Processing::Loader::PostgresLoader.new, Lanalytics::Processing::Loader::Neo4jLoader.new ])
    pipeline.process(data)

    data = FactoryGirl.attributes_for(:amqp_enrollment)
    pipeline = Lanalytics::Processing::Pipeline.new('moocdb_user_enrollment', Lanalytics::Processing::ProcessingAction::CREATE,
      [ Lanalytics::Processing::Extractor::AmqEventExtractor.new(:ENROLLMENT) ],
      [ Lanalytics::Processing::Transformer::AnonymousDataFilter.new, Lanalytics::Processing::Transformer::MoocdbDataTransformer.new ],
      [ Lanalytics::Processing::Loader::PostgresLoader.new, Lanalytics::Processing::Loader::Neo4jLoader.new ])
    pipeline.process(data)


    data = FactoryGirl.attributes_for(:amqp_user)
    pipeline = Lanalytics::Processing::Pipeline.new('openhpi_graph_user_create', Lanalytics::Processing::ProcessingAction::CREATE,
      [ Lanalytics::Processing::Extractor::AmqEventExtractor.new(:USER) ],
      [ Lanalytics::Processing::Transformer::AnonymousDataFilter.new, Lanalytics::Processing::Transformer::NosqlDataSchemaTransformer.new ],
      [ Lanalytics::Processing::Loader::Neo4jLoader.new(:nosql_neo) ])
    pipeline.process(data)

    data = FactoryGirl.attributes_for(:amqp_course)
    pipeline = Lanalytics::Processing::Pipeline.new('openhpi_graph_course_create', Lanalytics::Processing::ProcessingAction::CREATE,
      [ Lanalytics::Processing::Extractor::AmqEventExtractor.new(:COURSE) ],
      [ Lanalytics::Processing::Transformer::AnonymousDataFilter.new, Lanalytics::Processing::Transformer::NosqlDataSchemaTransformer.new ],
      [ Lanalytics::Processing::Loader::Neo4jLoader.new(:nosql_neo) ])
    pipeline.process(data)

    data = FactoryGirl.attributes_for(:amqp_enrollment)
    pipeline = Lanalytics::Processing::Pipeline.new('openhpi_graph_enrollment_create', Lanalytics::Processing::ProcessingAction::CREATE,
      [ Lanalytics::Processing::Extractor::AmqEventExtractor.new(:ENROLLMENT) ],
      [ Lanalytics::Processing::Transformer::AnonymousDataFilter.new, Lanalytics::Processing::Transformer::NosqlDataSchemaTransformer.new ],
      [ Lanalytics::Processing::Loader::Neo4jLoader.new(:nosql_neo) ])
    pipeline.process(data)

    # data = FactoryGirl.attributes_for(:amqp_enrollment)
    # pipeline = Lanalytics::Processing::Pipeline.new('user_enrollment', Lanalytics::Processing::ProcessingAction::CREATE,
    #   [ Lanalytics::Processing::Extractor::AmqEventExtractor.new(:ENROLLMENT) ],
    #   [ Lanalytics::Processing::Transformer::AnonymousDataFilter.new, Lanalytics::Processing::Transformer::MoocdbDataTransformer.new ],
    #   [ Lanalytics::Processing::Loader::PostgresLoader.new, Lanalytics::Processing::Loader::Neo4jLoader.new ])
    # pipeline.process(data)
  end

end