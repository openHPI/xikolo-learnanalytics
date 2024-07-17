# frozen_string_literal: true

require 'rails_helper'

describe Lanalytics::Processing::PipelineManager do
  describe '(Instantiation)' do
    it 'is implemented as Singleton' do
      expect { described_class.new }.to raise_error(NoMethodError)

      expect(described_class).to respond_to(:instance)
      expect(described_class.instance).to be(described_class.instance) # rubocop:disable RSpec/IdenticalEqualityAssertion
    end
  end

  describe '(Pipeline Configuration)' do
    it 'ensures to only load *.prb files' do
      # Raise ArgumentError.new("Wrong file format. It has to be a ruby file ending with '*.prb'.")
      expect do
        described_class.setup_pipelines(Rails.root.join('spec/lanalytics/processing/pipelines/dummy_pipeline_manager.rb'))
      end.to raise_error ArgumentError, /^File '.*' has to end with 'prb'\.$/

      expect do
        described_class.setup_pipelines(Rails.root.join('spec/lanalytics/processing/pipelines/dummy_pipeline_manager.txt'))
      end.to raise_error ArgumentError, /^File '.*' has to end with 'prb'\.$/

      # Raise ArgumentError.new("File '...' does not exists.")
      expect do
        described_class.setup_pipelines(Rails.root.join('spec/lanalytics/processing/pipelines/blabla_pipeline_manager.prb'))
      end.to raise_error ArgumentError, /^File '.*' does not exist\.$/
    end

    it 'raises error if pipeline file is not ruby code' do
      expect do
        described_class.setup_pipelines(Rails.root.join('spec/lanalytics/processing/pipelines/erroneous_pipeline.prb'))
      end.to raise_error(/^The following error occurred when registering pipeline/)
    end

    it 'loads pipelines from *.prb file' do
      described_class.setup_pipelines(Rails.root.join('spec/lanalytics/processing/pipelines/dummy_pipeline_manager.prb'))

      pipeline1 = described_class.instance.find_piplines(:pipeline_manager_spec, Lanalytics::Processing::Action::CREATE, 'xikolo.lanalytics.pipeline_manager.pipeline1')
      expect(pipeline1).not_to be_nil
      expect(pipeline1).to be_an Array
      expect(pipeline1.length).to eq 1

      pipeline2 = described_class.instance.find_piplines(:pipeline_manager_spec, Lanalytics::Processing::Action::CREATE, 'xikolo.lanalytics.pipeline_manager.pipeline2')
      expect(pipeline2).not_to be_nil
      expect(pipeline2).to be_an Array
      expect(pipeline2.length).to eq 1

      pipeline3 = described_class.instance.find_piplines(:pipeline_manager_spec, Lanalytics::Processing::Action::CREATE, 'xikolo.lanalytics.pipeline_manager.pipeline3')
      expect(pipeline3).not_to be_nil
      expect(pipeline3).to be_an Array
      expect(pipeline3.length).to eq 1
    end

    it 'saves pipeline accordingly' do
      pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_manager_spec, Lanalytics::Processing::Action::CREATE,
        [Lanalytics::Processing::Extractor::ExtractStep.new],
        [Lanalytics::Processing::Transformer::TransformStep.new],
        [Lanalytics::Processing::Loader::DummyLoadStep.new])

      described_class.instance.register_pipeline(pipeline)
      pipelines = described_class.instance.find_piplines(:pipeline_manager_spec, Lanalytics::Processing::Action::CREATE, 'xikolo.lanalytics.pipeline')
      expect(pipelines).to be_an Array
      expect(pipelines).not_to be_empty
      expect(pipelines.length).to eq 1
      expect(pipelines.first).to eq pipeline
    end
  end

  describe '(Pipeline Access)' do
    it 'aggregates pipeline across schemas' do
      pipeline = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_manager_spec, Lanalytics::Processing::Action::CREATE,
        [Lanalytics::Processing::Extractor::ExtractStep.new],
        [Lanalytics::Processing::Transformer::TransformStep.new],
        [Lanalytics::Processing::Loader::DummyLoadStep.new])
      described_class.instance.register_pipeline(pipeline)

      pipeline1 = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_manager_spec1, Lanalytics::Processing::Action::CREATE,
        [Lanalytics::Processing::Extractor::ExtractStep.new],
        [Lanalytics::Processing::Transformer::TransformStep.new],
        [Lanalytics::Processing::Loader::DummyLoadStep.new])
      described_class.instance.register_pipeline(pipeline1)

      pipeline2 = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_manager_spec2, Lanalytics::Processing::Action::CREATE,
        [Lanalytics::Processing::Extractor::ExtractStep.new],
        [Lanalytics::Processing::Transformer::TransformStep.new],
        [Lanalytics::Processing::Loader::DummyLoadStep.new])
      described_class.instance.register_pipeline(pipeline2)

      pipeline3 = Lanalytics::Processing::Pipeline.new('xikolo.lanalytics.pipeline', :pipeline_manager_spec3, Lanalytics::Processing::Action::CREATE,
        [Lanalytics::Processing::Extractor::ExtractStep.new],
        [Lanalytics::Processing::Transformer::TransformStep.new],
        [Lanalytics::Processing::Loader::DummyLoadStep.new])
      described_class.instance.register_pipeline(pipeline3)

      pipelines = described_class.instance.schema_pipelines_with(Lanalytics::Processing::Action::CREATE, 'xikolo.lanalytics.pipeline')
      expect(pipelines).to be_an Hash
      expect(pipelines).not_to be_empty
      expect(pipelines.size).to eq 4
      expect(pipelines).to include :pipeline_manager_spec, :pipeline_manager_spec1, :pipeline_manager_spec2, :pipeline_manager_spec3
      expect(pipelines.values).to include pipeline, pipeline1, pipeline2, pipeline3
    end
  end
end
