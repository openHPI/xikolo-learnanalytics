require 'rails_helper'

RSpec.describe Lanalytics::Model::StmtVerb do

  it "initializes correctly" do
    stmt_verb_type = :PLAY_VIDEO
    stmt_verb = Lanalytics::Model::StmtVerb.new(stmt_verb_type)
    expect(stmt_verb.type).to be_a(Symbol)
    expect(stmt_verb.type).to be(stmt_verb_type.to_sym)
  end

  describe "(JSON De-/Serialization)" do

    before(:each) do
      @stmt_verb = FactoryBot.build(:stmt_verb)
      @stmt_verb_hash = FactoryBot.attributes_for(:stmt_verb)
    end

    it "from json hash" do
      stmt_verb = Lanalytics::Model::StmtVerb.new_from_json(@stmt_verb_hash)
      check_stmt_verb_properties(stmt_verb)
    end

    it "from json string" do
      stmt_verb = Lanalytics::Model::StmtVerb.new_from_json(JSON.dump(@stmt_verb_hash))
      check_stmt_verb_properties(stmt_verb)
    end

    it "to json string" do
      stmt_verb = FactoryBot.build(:stmt_verb)
      stmt_verb_json_str = JSON.dump(stmt_verb)
      expect(stmt_verb_json_str).to be_a(String)
      expect(JSON.parse(stmt_verb_json_str)).to include('json_class' => @stmt_verb.class.name, 'data' => {'type' => @stmt_verb.type.to_s})
    end

    def check_stmt_verb_properties(actual_stmt_verb)
      expect(actual_stmt_verb).to be_a(Lanalytics::Model::StmtVerb)
      expect(actual_stmt_verb.type).to eq(@stmt_verb.type)
    end
  end


end
