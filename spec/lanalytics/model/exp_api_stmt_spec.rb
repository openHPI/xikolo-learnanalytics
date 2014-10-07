require 'rails_helper'

RSpec.describe Lanalytics::Model::ExpApiStatement do


  describe "(Initializaiton)" do

    before(:each) do
      @stmt_user = FactoryGirl.build(:stmt_user)
      @stmt_verb = FactoryGirl.build(:stmt_verb)
      @stmt_resource = FactoryGirl.build(:stmt_resource)
      @stmt_timestap = DateTime.parse('8 May 1989 05:00:00')
      @stmt_result = { result: 1000 }
      @stmt_context = { location: 'Potsdam' }
    end

    it "initializes correctly" do
      stmt_user = Lanalytics::Model::ExpApiStatement.new(stmt_user, stmt_verb, stmt_resource, )
      expect(stmt.user).to be(@stmt_user)
      expect(stmt.verb).to be(@stmt_verb)
      expect(stmt.resource).to be(@stmt_resource)
      expect(stmt.timestamp).to be(@stmt_timestap)
      expect(stmt.with_result).to be(@stmt_result)
      expect(stmt.in_context).to be(@stmt_context)
    end

    it "should initilize even when context and result missing" do
      stmt = Lanalytics::Model::ExpApiStatement.new(@stmt_user, @stmt_verb, @stmt_resource, @stmt_timestamp)
      expect(stmt.user).to be(@stmt_user)
      expect(stmt.verb).to be(@stmt_verb)
      expect(stmt.resource).to be(@stmt_resource)
      expect(stmt.timestamp).to be(@stmt_timestap)
      expect(stmt.with_result).to be_nil
      expect(stmt.in_context).to be_nil
    end

    it "should not initilaize when a critical component (user, verb, resource, timestamp) is missing" do
      expect { resource = Lanalytics::Model::ExpApiStatement.new }.to raise_error

      for i in (0..16)
        stmt_user = (i&1) > 0 ? @stmt_user : nil
        stmt_verb = (i&2) > 0 ? @stmt_verb : nil
        stmt_resource = (i&3) > 0 ? @stmt_resource : nil
        stmt_timestamp = (i&4) > 0 ? @stmt_timestap : nil
        expect { resource = Lanalytics::Model::ExpApiStatement.new(stmt_user, stmt_verb, stmt_resource, stmt_timestamp) }.to raise_error
      end

      expect { resource = Lanalytics::Model::ExpApiStatement.new(nil, nil, nil, nil, @stmt_result, @stmt_context) }.to raise_error
    end

  end

  describe "doing JSON De-/Serialization" do
    before(:each) do
      @stmt = FactoryGirl.build(:stmt)
      @stmt_hash = FactoryGirl.attributes_for(:@stmt_hash)
    end

    it "from json hash" do
      stmt = Lanalytics::Model::ExpApiStatement.new_from_json(@stmt_hash)
      check_stmt_properties(stmt)
    end

    it "from json string" do
      stmt_json_str = JSON.dump(@stmt_hash)
      stmt = Lanalytics::Model::ExpApiStatement.new_from_json(stmt_json_str)
      check_stmt_properties(stmt)
    end

    it "from nil should raise error" do
      expect { stmt = Lanalytics::Model::ExpApiStatement.new_from_json(nil) }.to raise_error
    end

    it "to json string" do
      stmt = FactoryGirl.build(:stmt)
      stmt_json_str = JSON.dump(stmt)
      expect(stmt_json_str).to be_a(String)
      expect(JSON.parse(stmt_json_str)).to include({
        'json_class' => stmt.class.name,
        'data' => {
          'user' => JSON.dump(stmt.user),
          'verb' => JSON.dump(stmt.verb),
          'resource' => JSON.dump(stmt.resource),
          'timestamp' => JSON.dump(stmt.timestamp),
          'with_result' => JSON.dump(stmt.with_result),
          'in_context' => JSON.dump(stmt.in_context)
        }
      })
    end
  end

  #it "marshales correctly" do

  def check_stmt_properties(actual_stmt)
    expect(actual_stmt).to be_a(Lanalytics::Model::ExpApiStatement)

    expect(actual_stmt.user).to eq(@stmt.user)
    expect(actual_stmt.verb).to eq(@stmt.verb)
    expect(actual_stmt.resource).to eq(@stmt.resource)
    expect(actual_stmt.timestamp).to eq(@stmt.timestamp)
  end

end