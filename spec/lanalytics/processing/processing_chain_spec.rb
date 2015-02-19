require 'rails_helper'

describe Lanalytics::Processing::Pipeline, pending: true do

  describe "(Instantiation)" do

    it 'should initialize correctly with processing step array' do

      processing_step1 = Lanalytics::Processing::ProcessingStep.new
      processing_step2 = Lanalytics::Processing::ProcessingStep.new

      processing_chain = Lanalytics::Processing::ProcessingChain.new([ processing_step1, processing_step2 ])

      expect(processing_chain.processing_steps).to be_a(Array)
      expect(processing_chain.processing_steps.length).to eq(2)
    end

    it 'should initialize correctly with one processing step' do

      processing_step = Lanalytics::Processing::ProcessingStep.new

      processing_chain = Lanalytics::Processing::ProcessingChain.new(processing_step)

      expect(processing_chain.processing_steps).to be_a(Array)
      expect(processing_chain.processing_steps.length).to eq(1)
    end

    it "should initialize an empty processing chain" do
      processing_chain = Lanalytics::Processing::ProcessingChain.new

      expect(processing_chain.processing_steps).to be_a(Array)
      expect(processing_chain.processing_steps).to be_empty
    end

    it 'should fail when not initialized with proper processing steps' do

      expect { Lanalytics::Processing::ProcessingChain.new([{}, double("dummy_processing_step")]) }.to raise_error(ArgumentError)
    end
  end

  describe '(Processing)' do

    it 'should stop when data is nil' do

      data = FactoryGirl.attributes_for(:amqp_learning_room)

      processing_step = Lanalytics::Processing::ProcessingStep.new
      expect(processing_step).to receive(:process).with(data, [], {})

      processing_chain = Lanalytics::Processing::ProcessingChain.new(processing_step)

      processing_chain.process(data)
    end


  end
end