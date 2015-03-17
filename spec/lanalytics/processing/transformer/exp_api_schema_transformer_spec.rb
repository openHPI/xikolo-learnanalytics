require 'rails_helper'

describe Lanalytics::Processing::Transformer::ExpApiSchemaTransformer do

  before(:each) do
    @original_event = FactoryGirl.attributes_for(:amqp_exp_stmt).with_indifferent_access
    @processing_units = [ Lanalytics::Processing::Unit.new(:exp_event, @original_event) ]
    @load_commands = []
    @pipeline_ctx = nil

    @exp_api_transformer = Lanalytics::Processing::Transformer::ExpApiSchemaTransformer.new
  end


  it 'should transform processing unit to nested (LoaORM) entity' do
   
    @exp_api_transformer.transform(@original_event, @processing_units, @load_commands, @pipeline_ctx)

    expect(@load_commands.length).to eq(1)
    create_exp_event_command = @load_commands.first
    expect(create_exp_event_command).to be_a(Lanalytics::Processing::LoadORM::CreateCommand)
    entity = create_exp_event_command.entity
    expect(entity).to be_a(Lanalytics::Processing::LoadORM::Entity)
    expect(entity.attributes.length).to eq(6)
    
    nested_user_entity = entity.attributes[0]
    expect(nested_user_entity.name).to eq(:user)
    expect(nested_user_entity.data_type).to eq(:entity)
    expect(nested_user_entity.value).to be_a(Lanalytics::Processing::LoadORM::Entity)
    
    nested_verb_attribute = entity.attributes[1]
    expect(nested_verb_attribute.value).to eq(:VIDEO_PLAY)

    nested_resource_entity = entity.attributes[2]
    expect(nested_resource_entity.name).to eq(:resource)
    expect(nested_resource_entity.data_type).to eq(:entity)
    expect(nested_resource_entity.value).to be_a(Lanalytics::Processing::LoadORM::Entity)

    timestamp_attribute = entity.attributes[3]
    expect(timestamp_attribute.name).to eq(:timestamp)
    expect(timestamp_attribute.value).to eq("2014-10-27T14:59:08+01:00")

    with_result_attribute = entity.attributes[4]
    expect(with_result_attribute.name).to eq(:with_result)
    expect(with_result_attribute.data_type).to eq(:entity)
    expect(with_result_attribute.value).to be_a(Lanalytics::Processing::LoadORM::Entity)
    expect(with_result_attribute.value.attributes).to be_empty

    in_context_attribute = entity.attributes[5]
    expect(in_context_attribute.name).to eq(:in_context)
    expect(in_context_attribute.data_type).to eq(:entity)
    expect(in_context_attribute.value).to be_a(Lanalytics::Processing::LoadORM::Entity)
    expect(in_context_attribute.value.attributes.length).to eq(2)
    expect(in_context_attribute.value.attributes[0].name).to eq("current_time")
    expect(in_context_attribute.value.attributes[0].value).to eq("67.698807")
    expect(in_context_attribute.value.attributes[1].name).to eq("current_speed")
    expect(in_context_attribute.value.attributes[1].value).to eq("1")
    
  end

  it 'should only transform processing unit of type :exp_event' do
    @original_event = FactoryGirl.attributes_for(:amqp_enrollment).with_indifferent_access
    @processing_units = [ Lanalytics::Processing::Unit.new(:enrollment, @original_event) ]
    @exp_api_transformer.transform(@original_event, @processing_units, @load_commands, @pipeline_ctx)
    expect(@load_commands).to be_an(Array)
    expect(@load_commands).to be_empty
  end

end