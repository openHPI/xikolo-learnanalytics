# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lanalytics::Model::StmtVerb do
  it 'initializes correctly' do
    stmt_verb_type = :PLAY_VIDEO
    stmt_verb = described_class.new(stmt_verb_type)
    expect(stmt_verb.type).to be_a(Symbol)
    expect(stmt_verb.type).to be(stmt_verb_type.to_sym)
  end

  describe '(JSON De-/Serialization)' do
    it 'accepts JSON hash' do
      stmt_verb = described_class.new_from_json(type: 'SOME_VERB')
      expect(stmt_verb).to be_a described_class
      expect(stmt_verb.type).to eq :SOME_VERB
    end

    it 'accepts JSON string' do
      stmt_verb = described_class.new_from_json(JSON.dump(type: 'SOME_VERB'))
      expect(stmt_verb).to be_a described_class
      expect(stmt_verb.type).to eq :SOME_VERB
    end

    it 'can be dumped to JSON' do
      stmt_verb = described_class.new('SOME_VERB')
      stmt_verb_json_str = JSON.dump(stmt_verb)
      expect(stmt_verb_json_str).to be_a(String)
      expect(JSON.parse(stmt_verb_json_str)).to include(
        'json_class' => 'Lanalytics::Model::StmtVerb',
        'data' => {'type' => 'SOME_VERB'},
      )
    end
  end
end
