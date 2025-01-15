# frozen_string_literal: true

require 'rails_helper'

describe Lanalytics::Processing::Pipeline do
  let(:name)               { 'xikolo.lanalytics.pipeline' }
  let(:schema)             { :pipeline_spec }
  let(:processing_action)  { Lanalytics::Processing::Action::CREATE }

  describe '(Instantiation)' do
    it 'initializes correctly with mandatory params (name, schema, processing_action)' do
      pipeline = described_class.new(name, schema, processing_action)

      expect(pipeline.name).to eq 'xikolo.lanalytics.pipeline'
      expect(pipeline.schema).to eq :pipeline_spec
      expect(pipeline.processing_action).to eq Lanalytics::Processing::Action::CREATE
    end

    it 'only accepts four processing actions (CREATE, UPDATE, DESTROY, UNDEFINED)' do
      [
        Lanalytics::Processing::Action::CREATE,
        Lanalytics::Processing::Action::UPDATE,
        Lanalytics::Processing::Action::DESTROY,
        Lanalytics::Processing::Action::UNDEFINED,
      ].each do |action|
        correct_pipeline = described_class.new(name, schema, action)
        expect(correct_pipeline.processing_action).to eq action
      end

      expect do
        described_class.new(name, schema, :MERGE)
      end.to raise_error ArgumentError

      expect do
        described_class.new(name, schema, 'Lanalytics::Processing::Action::MERGE')
      end.to raise_error ArgumentError
    end

    it 'initializes correctly with ExtractSteps, TransformSteps and LoadSteps' do
      pipeline = described_class.new(
        'xikolo.lanalytics.pipeline',
        schema,
        Lanalytics::Processing::Action::CREATE,
        [Lanalytics::Processing::Extractor::ExtractStep.new],
        [Lanalytics::Processing::Transformer::TransformStep.new],
        [Lanalytics::Processing::Loader::DummyLoadStep.new],
      )

      extractors = pipeline.instance_variable_get(:@extractors)
      expect(extractors).to be_a Array
      expect(extractors).not_to be_empty
      expect(extractors.length).to eq 1

      transformers = pipeline.instance_variable_get(:@transformers)
      expect(transformers).to be_a Array
      expect(transformers).not_to be_empty
      expect(transformers.length).to eq 1

      loaders = pipeline.instance_variable_get(:@loaders)
      expect(loaders).to be_a Array
      expect(loaders).not_to be_empty
      expect(loaders.length).to eq 1
    end

    it 'initializes an empty pipeline' do
      pipeline = described_class.new(
        name,
        schema,
        processing_action,
        [],
        [],
        [],
      )
      expect(pipeline.instance_variable_get(:@extractors)).to be_empty
      expect(pipeline.instance_variable_get(:@transformers)).to be_empty
      expect(pipeline.instance_variable_get(:@loaders)).to be_empty

      pipeline = described_class.new(
        name,
        schema,
        processing_action,
      )
      expect(pipeline.instance_variable_get(:@extractors)).to be_empty
      expect(pipeline.instance_variable_get(:@transformers)).to be_empty
      expect(pipeline.instance_variable_get(:@loaders)).to be_empty
    end

    it 'fails when not initialized with proper processing steps' do
      expect do
        described_class.new(
          name,
          schema,
          processing_action,
          ['Lanalytics::Processing::Extractor::ExtractStep.new'], # Inject another type
          [Lanalytics::Processing::Transformer::TransformStep.new],
          [Lanalytics::Processing::Loader::DummyLoadStep.new],
        )
      end.to raise_error ArgumentError

      expect do
        described_class.new(
          name,
          schema,
          processing_action,
          [Lanalytics::Processing::Extractor::ExtractStep.new],
          ['Lanalytics::Processing::Transformer::TransformStep.new'],
          [Lanalytics::Processing::Loader::DummyLoadStep.new],
        )
      end.to raise_error ArgumentError

      expect do
        described_class.new(
          name,
          schema,
          processing_action,
          [Lanalytics::Processing::Extractor::ExtractStep.new],
          [Lanalytics::Processing::Transformer::TransformStep.new],
          ['Lanalytics::Processing::Loader::DummyLoadStep.new'],
        )
      end.to raise_error ArgumentError
    end
  end

  describe '(Processing)' do
    it 'calls the ExtractStep' do
      event_data = {dummy_prop: 'dummy_value'}

      extract_step = Lanalytics::Processing::Extractor::ExtractStep.new
      expect(extract_step).to receive(:extract).with(event_data, [], kind_of(Lanalytics::Processing::PipelineContext))

      transform_step = Lanalytics::Processing::Transformer::TransformStep.new
      expect(transform_step).to receive(:transform).with(event_data, [], [], kind_of(Lanalytics::Processing::PipelineContext))

      load_step = Lanalytics::Processing::Loader::DummyLoadStep.new
      expect(load_step).to receive(:load).with(event_data, [], kind_of(Lanalytics::Processing::PipelineContext))

      pipeline = described_class.new(
        name,
        schema,
        processing_action,
        [extract_step],
        [transform_step],
        [load_step],
      )
      pipeline.process(event_data)
    end

    it 'stops when data is nil' do
      extract_step = Lanalytics::Processing::Extractor::ExtractStep.new
      expect(extract_step).not_to receive(:extract)
      transform_step = Lanalytics::Processing::Transformer::TransformStep.new
      expect(transform_step).not_to receive(:transform)
      load_step = Lanalytics::Processing::Loader::DummyLoadStep.new
      expect(load_step).not_to receive(:load)

      pipeline = described_class.new(
        name,
        schema,
        processing_action,
        [extract_step],
        [transform_step],
        [load_step],
      )

      pipeline.process(nil)
    end
  end
end
