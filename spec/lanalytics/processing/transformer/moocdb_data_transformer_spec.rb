require 'rails_helper'

describe Lanalytics::Processing::Transformer::MoocdbDataTransformer do

  before(:each) do
    @load_commands = []
    @pipeline_ctx = nil

    @exp_api_transformer = Lanalytics::Processing::Transformer::MoocdbDataTransformer.new
  end

  def pipeline_ctx(processing_action)
    return Lanalytics::Processing::PipelineContext.new(
      Lanalytics::Processing::Pipeline.new(
        'xikolo.lanalytics.pipeline',
        :pipeline_spec,
        processing_action,
        [],
        [@exp_api_transformer],
        []
      ),
      {} # Empty options hash
    )
  end

  it "should transform processing unit of type 'user'" do
    @original_event = FactoryGirl.attributes_for(:amqp_user).with_indifferent_access
    @processing_units = [ Lanalytics::Processing::Unit.new(:USER, @original_event) ]
    @pipeline_ctx = pipeline_ctx(Lanalytics::Processing::Action::CREATE)
    @exp_api_transformer.transform(@original_event, @processing_units, @load_commands, @pipeline_ctx)

    expect(@load_commands.length).to eq(1)
    create_exp_event_command = @load_commands.first
    expect(create_exp_event_command).to be_a(Lanalytics::Processing::LoadORM::MergeEntityCommand)

    user_entity = create_exp_event_command.entity
    expect(user_entity.entity_key).to eq(:user_pii)
    expect(user_entity.primary_attribute.name).to eq(:username)
    expect(user_entity.primary_attribute.value).to_not eq(@original_event[:id]) # Because the value should be hashed
    expect(user_entity.attributes.map { | attr | attr.name }).to include(:global_user_id, :gender, :birthday, :ip, :country, :timezone_offset)
  end

  it "should transform processing unit of type 'course'" do
    @original_event = FactoryGirl.attributes_for(:amqp_course).with_indifferent_access
    @processing_units = [ Lanalytics::Processing::Unit.new(:COURSE, @original_event) ]
    @pipeline_ctx = pipeline_ctx(Lanalytics::Processing::Action::CREATE)
    @exp_api_transformer.transform(@original_event, @processing_units, @load_commands, @pipeline_ctx)

    expect(@load_commands.length).to eq(1)
    create_exp_event_command = @load_commands.first
    expect(create_exp_event_command).to be_a(Lanalytics::Processing::LoadORM::MergeEntityCommand)

    course_entity = create_exp_event_command.entity
    expect(course_entity.entity_key).to eq(:course)
    expect(course_entity.primary_attribute.name).to eq(:course_id)
    expect(course_entity.primary_attribute.value).to eq(@original_event[:id]) # Because the value should be hashed
    expect(course_entity.attributes.map { | attr | attr.name }).to include(:course_name, :course_start_date, :course_end_date)
  end


  it "should transform processing unit of type 'question'" do
    @original_event = FactoryGirl.attributes_for(:amqp_pinboard_question).with_indifferent_access
    @processing_units = [ Lanalytics::Processing::Unit.new(:QUESTION, @original_event) ]
    @pipeline_ctx = pipeline_ctx(Lanalytics::Processing::Action::CREATE)
    @exp_api_transformer.transform(@original_event, @processing_units, @load_commands, @pipeline_ctx)

    expect(@load_commands.length).to eq(2)
    create_exp_event_command = @load_commands.first
    expect(create_exp_event_command).to be_a(Lanalytics::Processing::LoadORM::MergeEntityCommand)
  end

end
