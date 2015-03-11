require 'rails_helper'

shared_examples 'an experience statement' do
  its(:entity_key) { is_expected.to eq :EXP_STATEMENT }
  it 'has the correct attributes' do
    expect(subject.attributes.map(&:name)).to match_array(%i(user verb resource timestamp in_context))
  end
end

describe Lanalytics::Processing::Transformer::ExpApiSchemaTransformer do
  let(:transformer) { described_class.new }
  let(:load_commands) { [] }
  let(:transform_method) { transformer.method("transform_#{type}_punit_to_create") }
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
        technical: false
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
        technical: false
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
        technical: false
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
        course_id: SecureRandom.uuid
      }
    end

    it_behaves_like 'an experience statement'
    it 'has the correct verb' do
      expect(subject[:verb].value).to eq :WATCHED_QUESTION
    end
  end
end
