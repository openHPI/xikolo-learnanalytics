require 'rails_helper'

RSpec.describe Lanalytics::Model::ExpApiStatement do


  describe "(Initialization)" do

    before(:each) do
      @stmt_user = FactoryGirl.build(:stmt_user)
      @stmt_verb = FactoryGirl.build(:stmt_verb)
      @stmt_resource = FactoryGirl.build(:stmt_resource)
      @stmt_timestamp = DateTime.parse('8 May 1989 05:00:00')
      @stmt_result = { result: 1000 }
      @stmt_context = { location: 'Potsdam' }
    end

    it "initializes correctly" do
      stmt = Lanalytics::Model::ExpApiStatement.new(@stmt_user, @stmt_verb, @stmt_resource, @stmt_timestamp, @stmt_result, @stmt_context)
      expect(stmt.user).to be(@stmt_user)
      expect(stmt.verb).to be(@stmt_verb)
      expect(stmt.resource).to be(@stmt_resource)
      expect(stmt.timestamp).to be(@stmt_timestamp)
      expect(stmt.with_result).to be(@stmt_result)
      expect(stmt.in_context).to be(@stmt_context)
    end

    it "should initialize even when context and result missing" do
      stmt = Lanalytics::Model::ExpApiStatement.new(@stmt_user, @stmt_verb, @stmt_resource, @stmt_timestamp)
      expect(stmt.with_result).to be_empty
      expect(stmt.in_context).to be_empty
    end

    it "should not initialize when 'type' or 'uuid' of stmt_resource or stmt_user are empty" do
      
      expect do
        stmt = Lanalytics::Model::ExpApiStatement.new(Lanalytics::Model::StmtUser.new(""), @stmt_verb, @stmt_resource, @stmt_timestamp, @stmt_result, @stmt_context)
      end.to raise_error(ArgumentError)
        
      expect do
        stmt = Lanalytics::Model::ExpApiStatement.new(@stmt_user, @stmt_verb, @stmt_resource, Lanalytics::Model::StmtResource.new(""), @stmt_result, @stmt_context)
      end.to raise_error(ArgumentError)

    end

    it "should not initialize when a critical component (user, verb, resource) is missing" do
      expect { resource = Lanalytics::Model::ExpApiStatement.new }.to raise_error

      for i in (0...7)
        stmt_user = (i&1) > 0 ? @stmt_user : nil
        stmt_verb = (i&2) > 0 ? @stmt_verb : nil
        stmt_resource = (i&4) > 0 ? @stmt_resource : nil
        failure_message =  "stmt_user:#{stmt_user ? 'not nil' : 'nil'}, stmt_verb: #{stmt_verb ? 'not nil' : 'nil'}, stmt_resource: #{stmt_resource ? 'not nil' : 'nil'}"
        expect do
          stmt = Lanalytics::Model::ExpApiStatement.new(stmt_user, stmt_verb, stmt_resource)
        end.to raise_error(ArgumentError), failure_message
      end

      expect { resource = Lanalytics::Model::ExpApiStatement.new(nil, nil, nil, nil, @stmt_result, @stmt_context) }.to raise_error
    end

    it "should initialize timestamp as current datetime when timestamp nil or not defined" do
      stmt = Lanalytics::Model::ExpApiStatement.new(@stmt_user, @stmt_verb, @stmt_resource)
      expect(stmt.timestamp).to be_within(1000).of(DateTime.now)

      stmt = Lanalytics::Model::ExpApiStatement.new(@stmt_user, @stmt_verb, @stmt_resource, nil)
      expect(stmt.timestamp).to be_within(1000).of(DateTime.now)
    end

    it "should understand a proper date time string" do
      stmt = Lanalytics::Model::ExpApiStatement.new(@stmt_user, @stmt_verb, @stmt_resource, '8 May 1989 05:00:00')
      expect(stmt.timestamp).to eq(DateTime.parse('8 May 1989 05:00:00'))

      expect do
        stmt = Lanalytics::Model::ExpApiStatement.new(@stmt_user, @stmt_verb, @stmt_resource, 'openhpi')
      end.to raise_error
    end

  end

  describe "(JSON De-/Serialization)" do
    before(:each) do
      @stmt = FactoryGirl.build(:stmt)
      # ::TODO This is ugly and needs to go to the factory
      @stmt_hash = FactoryGirl.attributes_for(:stmt) do | stmt_hash |
        stmt_hash[:user] = FactoryGirl.attributes_for(:stmt_user)
        stmt_hash[:verb] = FactoryGirl.attributes_for(:stmt_verb)
        stmt_hash[:resource] = FactoryGirl.attributes_for(:stmt_resource)
      end
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
      stmt_json_hash = JSON.parse(stmt_json_str)
      expect(stmt_json_hash).to include({ 'json_class' => stmt.class.name })
      expect(stmt_json_hash['data'].keys).to include('user', 'verb', 'resource', 'timestamp', 'with_result', 'in_context')
      #expect(stmt_json_hash).to include({
      #  'data' => {
      #    'user' => JSON.dump(stmt.user),
      #    'verb' => JSON.dump(stmt.verb),
      #    'resource' => JSON.dump(stmt.resource),
      #    'timestamp' => JSON.dump(stmt.timestamp),
      #    'with_result' => JSON.dump(stmt.with_result),
      #    'in_context' => JSON.dump(stmt.in_context)
      #  }
      #})
    end
  end

  describe "(Marshalling)" do

    it "should marshal the objects" do
      stmt = FactoryGirl.build(:stmt)
      marshalled_stmt = Marshal.dump(stmt)
      expect(marshalled_stmt).to be_a(String)
      expect(marshalled_stmt).to include(stmt.class.name)
      expect(marshalled_stmt).to include('Lanalytics::Model::StmtUser')
      expect(marshalled_stmt).to include('Lanalytics::Model::StmtVerb')
      expect(marshalled_stmt).to include('Lanalytics::Model::StmtResource')

    end

    it "should be able to do the whole cycle" do
      stmt = FactoryGirl.build(:stmt)
      marshalled_stmt = Marshal.dump(stmt)
      new_stmt = Marshal.load(marshalled_stmt)
      expect(new_stmt).to be_a(Lanalytics::Model::ExpApiStatement)
      expect(new_stmt).not_to be(stmt)
      expect(new_stmt).to eq(stmt)
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