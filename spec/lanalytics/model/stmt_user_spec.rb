require 'rails_helper'

RSpec.describe Lanalytics::Model::StmtUser do

  before(:each) do
    @stmt_user = FactoryBot.build(:stmt_user)
    @stmt_user_hash = FactoryBot.attributes_for(:stmt_user)
  end

  it "initializes correctly" do
    stmt_user_uuid = "1234567890"
    stmt_user = Lanalytics::Model::StmtUser.new(stmt_user_uuid)
    expect(stmt_user.type).to eq(:USER)
    expect(stmt_user.uuid).to eq(stmt_user_uuid)
  end

  describe "(JSON De-/Serialization)" do

    it "from json hash" do
      stmt_user = Lanalytics::Model::StmtUser.new_from_json(@stmt_user_hash)
      check_stmt_user_properties(stmt_user)
    end

    it "from json string" do
      stmt_user = Lanalytics::Model::StmtUser.new_from_json(JSON.dump(@stmt_user_hash))
      check_stmt_user_properties(stmt_user)
    end

    it "to json string" do
      stmt_user = FactoryBot.build(:stmt_user)
      stmt_user_json_str = JSON.dump(stmt_user)
      expect(stmt_user_json_str).to be_a(String)
      expect(JSON.parse(stmt_user_json_str)).to include('json_class' => @stmt_user.class.name, 'data' => {'type' => stmt_user.type.to_s, 'uuid' => stmt_user.uuid.to_s})
    end

  end

  def check_stmt_user_properties(actual_stmt_user)
    expect(actual_stmt_user).to be_a(Lanalytics::Model::StmtUser)
    expect(actual_stmt_user.type).to eq(@stmt_user.type)
    expect(actual_stmt_user.uuid).to eq(@stmt_user.uuid)
  end

end
