require 'rails_helper'

RSpec.describe Lanalytics::Model::StmtResource do

  describe "(Initialization)" do

  it "should not initialize when 'type' or 'uuid' are nil or empty" do
    expect { stmt_resource = Lanalytics::Model::StmtResource.new(nil, nil) }.to raise_error(ArgumentError)
    expect { stmt_resource = Lanalytics::Model::StmtResource.new('User', nil) }.to raise_error(ArgumentError)
    expect { stmt_resource = Lanalytics::Model::StmtResource.new('User', '') }.to raise_error(ArgumentError)
    expect { stmt_resource = Lanalytics::Model::StmtResource.new(nil, '1231451') }.to raise_error(ArgumentError)
    expect { stmt_resource = Lanalytics::Model::StmtResource.new('', '1231451') }.to raise_error(ArgumentError)
  end

  end

  describe "doing JSON De-/Serialization" do
    before(:each) do
      @resource = FactoryBot.build(:stmt_resource)
      @resource_hash = FactoryBot.attributes_for(:stmt_resource)
    end

    it "from json hash" do
      resource = Lanalytics::Model::StmtResource.new_from_json(@resource_hash)
      check_resource_properties(resource)
    end

    it "from json string" do
      resource_json_str = JSON.dump(@resource_hash)
      resource = Lanalytics::Model::StmtResource.new_from_json(resource_json_str)
      check_resource_properties(resource)
    end

    it "from nil should raise error" do
      expect { resource = Lanalytics::Model::StmtResource.new_from_json(nil) }.to raise_error
    end

    it "to json string" do
      resource = FactoryBot.build(:stmt_resource)
      resource_json_str = JSON.dump(resource)
      expect(resource_json_str).to be_a(String)
      expect(JSON.parse(resource_json_str)).to include('json_class' => resource.class.name)
      expect(JSON.parse(resource_json_str)).to include('data' => {'type' => resource.type.to_s, 'uuid' => resource.uuid.to_s})
    end
  end

  #it "marshales correctly" do

  def check_resource_properties(actual_resource)
    expect(actual_resource).to be_a(Lanalytics::Model::StmtResource)
    expect(actual_resource.type).to eq(@resource.type)
    expect(actual_resource.uuid).to eq(@resource.uuid)
  end

end