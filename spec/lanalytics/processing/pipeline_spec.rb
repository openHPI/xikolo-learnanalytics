require 'rails_helper'

describe Lanalytics::Processing::Pipeline do

  describe "(Instantiation)" do

    it 'should initialize correctly with mandatory params (name, schema, processing_action)' do

      pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, Lanalytics::Processing::ProcessingAction::CREATE)

      expect(pipeline.name).to eq 'xikolo.lanalytics.pipeline'
      expect(pipeline.schema).to eq :pipeline_spec
      expect(pipeline.processing_action).to eq Lanalytics::Processing::ProcessingAction::CREATE
    end

    it 'should only accept four processing actions (CREATE, UPDATE, DESTROY, UNDEFINED)' do

      [Lanalytics::Processing::ProcessingAction::CREATE,
        Lanalytics::Processing::ProcessingAction::UPDATE,
        Lanalytics::Processing::ProcessingAction::DESTROY,
        Lanalytics::Processing::ProcessingAction::UNDEFINED].each do | processing_action |
        correct_pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, processing_action)
        expect(correct_pipeline.processing_action).to eq processing_action
      end

      expect {
        broken_pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, :MERGE)
      }.to raise_error ArgumentError

      expect {
        broken_pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, 'Lanalytics::Processing::ProcessingAction::MERGE')
      }.to raise_error ArgumentError
    end

    it 'should initialize correctly with ExtractSteps, TransformSteps and LoadSteps' do

      pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, Lanalytics::Processing::ProcessingAction::CREATE,
        [Lanalytics::Processing::Extractor::ExtractStep.new],
        [Lanalytics::Processing::Transformer::TransformStep.new],
        [Lanalytics::Processing::Loader::DummyLoadStep.new])

      extractors = pipeline.instance_variable_get(:@extractors)
      expect(extractors).to be_a Array
      expect(extractors).to_not be_empty
      expect(extractors.length).to eq 1

      transformers = pipeline.instance_variable_get(:@transformers)
      expect(transformers).to be_a Array
      expect(transformers).to_not be_empty
      expect(transformers.length).to eq 1

      loaders = pipeline.instance_variable_get(:@loaders)
      expect(loaders).to be_a Array
      expect(loaders).to_not be_empty
      expect(loaders.length).to eq 1
    end

    it "should initialize an empty pipeline" do
      pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, Lanalytics::Processing::ProcessingAction::CREATE,
        [],
        [],
        [])
      expect(pipeline.instance_variable_get(:@extractors)).to be_empty
      expect(pipeline.instance_variable_get(:@transformers)).to be_empty
      expect(pipeline.instance_variable_get(:@loaders)).to be_empty

      pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, Lanalytics::Processing::ProcessingAction::CREATE)
      expect(pipeline.instance_variable_get(:@extractors)).to be_empty
      expect(pipeline.instance_variable_get(:@transformers)).to be_empty
      expect(pipeline.instance_variable_get(:@loaders)).to be_empty
    end

    it 'should fail when not initialized with proper processing steps' do

      expect do
        pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, Lanalytics::Processing::ProcessingAction::CREATE,
        ['Lanalytics::Processing::Extractor::ExtractStep.new'], # Inject another type
        [Lanalytics::Processing::Transformer::TransformStep.new],
        [Lanalytics::Processing::Loader::DummyLoadStep.new])
      end.to raise_error ArgumentError

      expect do
        pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, Lanalytics::Processing::ProcessingAction::CREATE,
        [Lanalytics::Processing::Extractor::ExtractStep.new],
        ['Lanalytics::Processing::Transformer::TransformStep.new'],
        [Lanalytics::Processing::Loader::DummyLoadStep.new])
      end.to raise_error ArgumentError

      expect do
        pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, Lanalytics::Processing::ProcessingAction::CREATE,
        [Lanalytics::Processing::Extractor::ExtractStep.new],
        [Lanalytics::Processing::Transformer::TransformStep.new],
        ['Lanalytics::Processing::Loader::DummyLoadStep.new'])
      end.to raise_error ArgumentError
    end
  end

  describe '(Processing)' do

    it 'should call the ExtractStep' do
      event_data = { dummy_prop: 'dummy_value' }

      extract_step = Lanalytics::Processing::Extractor::ExtractStep.new
      expect(extract_step).to receive(:extract).with(event_data, [], kind_of(Lanalytics::Processing::PipelineContext))
      transform_step = Lanalytics::Processing::Transformer::TransformStep.new
      expect(transform_step).to receive(:transform).with(event_data, [], [], kind_of(Lanalytics::Processing::PipelineContext))
      load_step = Lanalytics::Processing::Loader::DummyLoadStep.new
      expect(load_step).to receive(:load).with(event_data, [], kind_of(Lanalytics::Processing::PipelineContext))
      
      pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, Lanalytics::Processing::ProcessingAction::CREATE,
        [extract_step],
        [transform_step],
        [load_step])
      pipeline.process(event_data)
    end

    it 'should execute Pipeline without steps' do
      pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, Lanalytics::Processing::ProcessingAction::CREATE)
      pipeline.process({dummy_prop: 'dummy_value'})
    end

    it 'should stop when data is nil' do

      extract_step = Lanalytics::Processing::Extractor::ExtractStep.new
      expect(extract_step).to_not receive(:extract)
      transform_step = Lanalytics::Processing::Transformer::TransformStep.new
      expect(transform_step).to_not receive(:transform)
      load_step = Lanalytics::Processing::Loader::DummyLoadStep.new
      expect(load_step).to_not receive(:load)
      
      pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_spec, Lanalytics::Processing::ProcessingAction::CREATE,
        [extract_step],
        [transform_step],
        [load_step])

      pipeline.process(nil)
    end

  end
end