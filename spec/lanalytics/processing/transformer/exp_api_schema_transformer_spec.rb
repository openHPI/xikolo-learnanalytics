require 'rails_helper'

shared_examples 'an experience statement' do
  its(:entity_key) { is_expected.to eq :EXP_STATEMENT }
  it 'has the correct attributes' do
    expect(subject.attributes.map(&:name)).to match_array(
      %i(user verb resource timestamp in_context))
  end

  it 'has only non-nil attributes' do
    expect(subject.attributes.map(&:value).select(&:nil?).size).to eq 0
  end
end

describe Lanalytics::Processing::Transformer::ExpApiSchemaTransformer do

  before(:each) do
    @original_event = FactoryGirl.attributes_for(:amqp_exp_stmt).with_indifferent_access
    @processing_units = [ Lanalytics::Processing::Unit.new(:exp_event, @original_event) ]
    @load_commands = []
    @pipeline_ctx = OpenStruct.new processing_action: :CREATE

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

  let(:transformer) { described_class.new }
  let(:load_commands) { [] }
  let(:transform_method) do
    transformer.method("transform_#{type}_punit_to_create")
  end

  subject do
    transform_method.call(processing_unit, load_commands)
    load_commands.first.entity
  end

  describe 'ask question' do
    let(:type) { 'question' }
    let(:processing_unit) do
      {
        id: '00000001-3500-4444-9999-000000000001',
        title: 'Title',
        text: 'Text',
        user_id: SecureRandom.uuid,
        course_id: SecureRandom.uuid,
        technical: false,
        created_at: Time.now
      }
    end

    it_behaves_like 'an experience statement'
    it 'has the correct verb' do
      expect(subject[:verb].value).to eq :ASKED_QUESTION
    end
  end

  describe 'answer_question' do
    let(:type) { 'answer' }
    let(:processing_unit) do
      {
        id: '00000002-3500-4444-9999-000000000001',
        user_id: SecureRandom.uuid,
        course_id: SecureRandom.uuid,
        technical: false,
        created_at: Time.now
      }
    end

    it_behaves_like 'an experience statement'
    it 'has the correct verb' do
      expect(subject[:verb].value).to eq :ANSWERED_QUESTION
    end
  end

  describe 'comment' do
    let(:type) { 'comment' }
    let(:processing_unit) do
      {
        id: '00000003-3500-4444-9999-000000000001',
        text: 'Text',
        user_id: SecureRandom.uuid,
        course_id: SecureRandom.uuid,
        technical: false,
        created_at: Time.now
      }
    end

    it_behaves_like 'an experience statement'
    it 'has the correct verb' do
      expect(subject[:verb].value).to eq :COMMENTED
    end
  end

  describe 'visit' do
    let(:type) { 'visit' }
    let(:processing_unit) do
      {
        id: '00000005-3300-4444-9999-000000000001',
        item_id: '00000003-3300-4444-9999-000000000001',
        content_type: 'video',
        user_id: '00000001-3300-4444-9999-000000000001',
        course_id: SecureRandom.uuid,
        created_at: Time.now
      }
    end

    it_behaves_like 'an experience statement'
    it 'has the correct verb' do
      expect(subject[:verb].value).to eq :VISITED
    end
  end

  describe 'watch' do
    let(:type) { 'watch' }
    let(:processing_unit) do
      {
        id: '00000003-3500-4444-9999-000000000001',
        question_id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        course_id: SecureRandom.uuid,
        updated_at: Time.now
      }
    end

    it_behaves_like 'an experience statement'
    it 'has the correct verb' do
      expect(subject[:verb].value).to eq :WATCHED_QUESTION
    end
  end

  describe 'watch' do
    let(:type) { 'watch' }
    let(:processing_unit) do
      {
        id: '00000003-3500-4444-9999-000000000001',
        question_id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        course_id: SecureRandom.uuid,
        updated_at: Time.now
      }
    end

    it_behaves_like 'an experience statement'
    it 'has the correct verb' do
      expect(subject[:verb].value).to eq :WATCHED_QUESTION
    end
  end

  describe 'enrollment_completed' do
    let(:type) { 'enrollment_completed' }
    let(:processing_unit) do
      {
        id: '00000003-3500-4444-9999-000000000001',
        user_id: SecureRandom.uuid,
        course_id: SecureRandom.uuid,
        updated_at: Time.now,
        points: {
          achieved: 156.2,
          maximal: 180.0,
          percentage: 86.8
        },
        certificates: {
          confirmation_of_participation: true,
          record_of_achievement: false,
          certificate: nil
        },
        completed: true,
        quantile: 0.88
      }
    end

    it_behaves_like 'an experience statement'

    it 'has the correct verb' do
      expect(subject[:verb].value).to eq :COMPLETED_COURSE
    end

    it 'has the correct attributes' do
      [:course_id, :quantile].each do |key|
        expect(subject[:in_context].value[key.to_s].value).to eq processing_unit[key]
      end
    end

    it 'has the correct points' do
      [:achieved, :maximal, :percentage].each do |key|
        expect(subject[:in_context].value["points_#{key}"].value).to eq processing_unit[:points][key]
      end
    end

    it 'has the correct points' do
      [
        :received_confirmation_of_participation,
        :received_record_of_achievement,
        :received_certificate
      ].each do |key|
        # Towards correct boolean naming received_ ...
        value = processing_unit[:certificates][key.to_s.gsub('received_', '').to_sym]
        expect(subject[:in_context].value[key.to_s].value).to eq(
          value.nil? ? false : value
        )
      end
    end
  end
end
