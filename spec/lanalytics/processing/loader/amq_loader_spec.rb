require 'rails_helper'

describe Lanalytics::Processing::Loader::AmqLoader do

  let(:original_event) do
    FactoryBot.attributes_for(:amqp_exp_stmt).with_indifferent_access
  end
  let(:load_command) { Lanalytics::Processing::LoadORM::CreateCommand.new entity }
  let(:entity) do
    Lanalytics::Processing::LoadORM::Entity.create(:dummy_type) do
      with_primary_attribute :dummy_uuid, :uuid, '1234567890'
      with_attribute :dummy_string_property, :string, 'dummy_string_value'
      with_attribute :dummy_int_property, :int, 1234
      with_attribute :dummy_float_property, :float, 1234.0
      with_attribute :dummy_timestamp_property, :timestamp, Time.zone.parse('2015-03-10 09:00:00 +0100')
    end
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