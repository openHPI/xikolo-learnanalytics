require 'rails_helper'

describe Lanalytics::Processing::Loader::AmqLoader do

  let(:original_event) do
    FactoryBot.attributes_for(:amqp_exp_stmt).with_indifferent_access
  end
  let(:load_command) do
    FactoryBot.build(:load_command_with_entity)
  end

  before(:each) do
    @route = 'xikolo.lanalytics.test_amq_loader'
    @amq_loader = Lanalytics::Processing::Loader::AmqLoader.new(@route)
  end

  it 'is available if there is a connection to the message broker' do
    Msgr.client.start
    expect(@amq_loader.available?).to be true
  end

  it 'is not available if there is no connection to the message broker' do
    Msgr.client.stop
    expect(@amq_loader.available?).to be false
  end

  it 'publishes the entity to the specified route' do
    pipeline_ctx = OpenStruct.new processing_action: :CREATE
    expect(Msgr).to receive(:publish).with(hash_including({:dummy_uuid => '1234567890', :dummy_int_property => 1234}), to: @route)
    @amq_loader.load(original_event, [load_command], pipeline_ctx)
  end
end