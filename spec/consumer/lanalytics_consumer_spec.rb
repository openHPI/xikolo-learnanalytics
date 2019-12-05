require 'rails_helper'

describe LanalyticsConsumer do
  include LanalyticsConsumerSpecsHelper

  before(:each) do
    stub_request(:head, 'http://localhost:9200/')
      .to_return(status: 200)
  end
  let(:consumer) { described_class.new }

  describe "(:create)" do
    before(:each) do
      @dummy_event_data = {dummy_property: 'dummy_value'}
      prepare_rabbitmq_stubs(consumer, @dummy_event_data, 'xikolo.lanalytics.test_event.create')
    end

    it 'should find and trigger the correct pipeline' do
      # Add dummy pipeline to PipelineManager
      dummy_pipeline = Lanalytics::Processing::Pipeline.new(
        'xikolo.lanalytics.test_event.create',
        :lanalytics_consumer_spec,
        Lanalytics::Processing::Action::CREATE
      )
      Lanalytics::Processing::PipelineManager.instance.register_pipeline(dummy_pipeline)

      # Check whether the corresponding pipeline has been triggered
      expect(dummy_pipeline).to receive(:process).with(@dummy_event_data, kind_of(Hash))

      consumer.create
    end

    it 'should trigger all registered pipelines' do
      dummy_pipeline1 = Lanalytics::Processing::Pipeline.new(
        'xikolo.lanalytics.test_event.create',
        :lanalytics_consumer_spec,
        Lanalytics::Processing::Action::CREATE
      )
      Lanalytics::Processing::PipelineManager.instance.register_pipeline(dummy_pipeline1)
      dummy_pipeline2 = Lanalytics::Processing::Pipeline.new(
        'xikolo.lanalytics.test_event.create',
        :lanalytics_consumer_spec2,
        Lanalytics::Processing::Action::CREATE
      )
      Lanalytics::Processing::PipelineManager.instance.register_pipeline(dummy_pipeline2)
      dummy_pipeline3 = Lanalytics::Processing::Pipeline.new(
        'xikolo.lanalytics.test_event.create',
        :lanalytics_consumer_spec3,
        Lanalytics::Processing::Action::CREATE
      )
      Lanalytics::Processing::PipelineManager.instance.register_pipeline(dummy_pipeline3)

      # Check whether the three corresponding pipelines have been triggered
      # Find the pipeline that should be processed
      expect(dummy_pipeline1).to receive(:process).with(@dummy_event_data, kind_of(Hash))
      expect(dummy_pipeline2).to receive(:process).with(@dummy_event_data, kind_of(Hash))
      expect(dummy_pipeline3).to receive(:process).with(@dummy_event_data, kind_of(Hash))

      consumer.create
    end
  end

  describe "(:update)" do
    before(:each) do
      @dummy_event_data = {dummy_property: 'dummy_value'}
      prepare_rabbitmq_stubs(consumer, @dummy_event_data, 'xikolo.lanalytics.test_event.update')
    end

    it 'should find and trigger the correct pipeline' do
      # Add dummy pipeline to PipelineManager
      dummy_pipeline = Lanalytics::Processing::Pipeline.new(
        'xikolo.lanalytics.test_event.update',
        :lanalytics_consumer_spec,
        Lanalytics::Processing::Action::UPDATE
      )
      Lanalytics::Processing::PipelineManager.instance.register_pipeline(dummy_pipeline)

      # Check whether the corresponding pipeline has been triggered
      expect(dummy_pipeline).to receive(:process).with(@dummy_event_data, kind_of(Hash))

      consumer.update
    end
  end

  describe "(:destroy)" do
    before(:each) do
      @dummy_event_data = {dummy_property: 'dummy_value'}
      prepare_rabbitmq_stubs(consumer, @dummy_event_data, 'xikolo.lanalytics.test_event.destroy')
    end

    it 'should find and trigger the correct pipeline' do
      # Add dummy pipeline to PipelineManager
      dummy_pipeline = Lanalytics::Processing::Pipeline.new(
        'xikolo.lanalytics.test_event.destroy',
        :lanalytics_consumer_spec,
        Lanalytics::Processing::Action::DESTROY
      )
      Lanalytics::Processing::PipelineManager.instance.register_pipeline(dummy_pipeline)

      # Check whether the corresponding pipeline has been triggered
      expect(dummy_pipeline).to receive(:process).with(@dummy_event_data, kind_of(Hash))

      consumer.destroy
    end
  end

  describe "(:handle_user_event)" do
    before(:each) do
      prepare_rabbitmq_stubs(consumer, dummy_event_data, 'xikolo.lanalytics.test_event.handle_user_event')

      Lanalytics::Processing::PipelineManager.instance.register_pipeline(dummy_pipeline)
    end

    # Add dummy pipeline to PipelineManager
    let(:dummy_pipeline) do
      Lanalytics::Processing::Pipeline.new(
        'xikolo.lanalytics.test_event.handle_user_event',
        :lanalytics_consumer_spec,
        Lanalytics::Processing::Action::CREATE
      )
    end
    let(:dummy_event_data) { {dummy_property: 'dummy_value'} }

    it 'finds and triggers the correct pipeline' do
      # Check whether the corresponding pipeline has been triggered
      expect(dummy_pipeline).to receive(:process).with(dummy_event_data, kind_of(Hash))

      consumer.handle_user_event
    end

    describe 'loading into Postgres' do
      let(:dummy_pipeline) do
        Lanalytics::Processing::Pipeline.new(
          'xikolo.lanalytics.test_event.handle_user_event',
          :lanalytics_consumer_spec,
          Lanalytics::Processing::Action::CREATE,
          [Lanalytics::Processing::Extractor::AmqEventExtractor.new(:exp_event)],
          [Lanalytics::Processing::Transformer::ExpApiNativeSchemaTransformer.new],
          [Lanalytics::Processing::Loader::PostgresLoader.new(pg_conn)],
        )
      end
      let(:pg_conn) do
        instance_double(Lanalytics::Processing::Datasources::PostgresqlDatasource).tap do |datasource|
          allow(datasource).to receive(:ping).and_return(true)
          allow(datasource).to receive(:exec)
        end
      end
      let(:dummy_event_data) do
        {
          user: {uuid: '00000003-3100-4444-9999-1234567890'},
          verb: {type: 'SOME_VERB'},
          resource: {
            type: 'SomeResource',
            uuid: '00000003-3100-4444-9999-0987654321',
            properties: {propertyA: 'property1', propertyB: 'property2'},
          },
          timestamp: Time.zone.parse('8 May 1989 05:00:00').to_datetime,
          with_result: {result: 1000},
          in_context: {location: 'Potsdam'},
        }
      end

      it 'sends data to the database' do
        expect(pg_conn).to receive(:exec).once

        consumer.handle_user_event
      end

      context 'with null bytes in the payload' do
        let(:dummy_event_data) do
          super().merge(in_context: {location: "THE_PLACE_WHERE_HACKERS_\x00_LIVE"})
        end

        it 'still sends data to the database' do
          expect(pg_conn).to receive(:exec).once

          consumer.handle_user_event
        end
      end
    end
  end

end
