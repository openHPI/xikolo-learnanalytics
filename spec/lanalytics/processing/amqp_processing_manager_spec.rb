require 'rails_helper'

describe Lanalytics::Processing::AmqpProcessingManager do

  describe "(Instantiation)" do

    it "is implemented as Singleton" do
      expect{ Lanalytics::Processing::AmqpProcessingManager.new }.to raise_error

      expect(Lanalytics::Processing::AmqpProcessingManager).to respond_to(:instance)
      expect(Lanalytics::Processing::AmqpProcessingManager.instance).to be(Lanalytics::Processing::AmqpProcessingManager.instance)
    end
  end

  describe "(Processing Configuration)" do

    it 'should understand processing.yml' do
      
      amqp_processing_manager = Lanalytics::Processing::AmqpProcessingManager.load_processing_definitions("#{Rails.root}/spec/config/processing.yml")

      expect(amqp_processing_manager).to be(Lanalytics::Processing::AmqpProcessingManager.instance)

      internal_processing_map = amqp_processing_manager.instance_eval { @processing_map }
      expect(internal_processing_map).to include('xikolo.account.user.create')
      expect(internal_processing_map).to include('xikolo.account.user.update')
      expect(internal_processing_map).to include('xikolo.account.user.destroy')

      [internal_processing_map['xikolo.account.user.create'], internal_processing_map['xikolo.account.user.update'], internal_processing_map['xikolo.account.user.destroy']].each do | processing_chain |
        expect(processing_chain).to be_a(Lanalytics::Processing::ProcessingChain)
        expect(processing_chain.processing_steps.length).to eq(3)
        expect(processing_chain.processing_steps[0]).to be_a(Lanalytics::Processing::Filter::UserDataFilter)
        expect(processing_chain.processing_steps[1]).to be_a(Lanalytics::Processing::Processor::LoggerProcessor)
        expect(processing_chain.processing_steps[2]).to be_a(Lanalytics::Processing::Processor::Neo4jProcessor)
      end

      expect(internal_processing_map).to include('xikolo.course.course.create')
      expect(internal_processing_map).to include('xikolo.course.course.update')
      expect(internal_processing_map).to include('xikolo.course.course.destroy')

      [internal_processing_map['xikolo.course.course.create'], internal_processing_map['xikolo.course.course.update'], internal_processing_map['xikolo.course.course.destroy']].each do | processing_chain |
        expect(processing_chain).to be_a(Lanalytics::Processing::ProcessingChain)
        expect(processing_chain.processing_steps.length).to eq(3)
        expect(processing_chain.processing_steps[0]).to be_a(Lanalytics::Processing::Filter::CourseDataFilter)
        expect(processing_chain.processing_steps[1]).to be_a(Lanalytics::Processing::Processor::LoggerProcessor)
        expect(processing_chain.processing_steps[2]).to be_a(Lanalytics::Processing::Processor::Neo4jProcessor)
      end      
    end

    it "should fail when registering empty processing steps for route" do
      expect do
        Lanalytics::Processing::AmqpProcessingManager.instance.add_processing_for('xikolo.lanalytics.test.create')
      end.to raise_error(ArgumentError)
    end

    it 'should register processing step for route' do

      processing_step = Lanalytics::Processing::ProcessingStep.new
      # expect(processing_step).to receive(:process).with(data, [], {})
      
      Lanalytics::Processing::AmqpProcessingManager.instance.add_processing_for('xikolo.lanalytics.test.create', [processing_step])

      internal_processing_map = Lanalytics::Processing::AmqpProcessingManager.instance.instance_eval { @processing_map }
      expect(internal_processing_map).to include('xikolo.lanalytics.test.create')
      expect(internal_processing_map['xikolo.lanalytics.test.create']).to be_a(Lanalytics::Processing::ProcessingChain)
      expect(internal_processing_map['xikolo.lanalytics.test.create'].processing_steps.length).to eq(1)
    end

  end

end