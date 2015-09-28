require 'rails_helper'

describe LanalyticsConsumer do
  include LanalyticsConsumerSpecsHelper

  before(:each) do
    @consumer = LanalyticsConsumer.new
  end

  describe "(:create)" do
    before(:each) do
      @dummy_event_data = { dummy_property: 'dummy_value' }
      prepare_rabbitmq_stubs(@dummy_event_data, 'xikolo.lanalytics.test_event.create')
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

      @consumer.create
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

      @consumer.create
    end
  end

  describe "(:update)" do
    before(:each) do
      @dummy_event_data = { dummy_property: 'dummy_value' }
      prepare_rabbitmq_stubs(@dummy_event_data, 'xikolo.lanalytics.test_event.update')
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

      @consumer.update
    end
  end

  describe "(:destroy)" do
    before(:each) do
      @dummy_event_data = { dummy_property: 'dummy_value' }
      prepare_rabbitmq_stubs(@dummy_event_data, 'xikolo.lanalytics.test_event.destroy')
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

      @consumer.destroy
    end
  end

  describe "(:handle_user_event)" do
    before(:each) do
      @dummy_event_data = { dummy_property: 'dummy_value' }
      prepare_rabbitmq_stubs(@dummy_event_data, 'xikolo.lanalytics.test_event.handle_user_event')
    end

    it 'should find and trigger the correct pipeline' do
      # Add dummy pipeline to PipelineManager
      dummy_pipeline = Lanalytics::Processing::Pipeline.new(
        'xikolo.lanalytics.test_event.handle_user_event',
        :lanalytics_consumer_spec,
        Lanalytics::Processing::Action::CREATE
      )
      Lanalytics::Processing::PipelineManager.instance.register_pipeline(dummy_pipeline)

      # Check whether the corresponding pipeline has been triggered
      expect(dummy_pipeline).to receive(:process).with(@dummy_event_data, kind_of(Hash))

      @consumer.handle_user_event
    end
  end


end
