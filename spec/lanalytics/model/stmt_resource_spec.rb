require 'rails_helper'

RSpec.describe Lanalytics::Model::StmtResource do

  before(:each) do
    @resource = FactoryGirl.build(:resource)
    @resource_hash = FactoryGirl.attributes_for(:resource)
  end

  describe "doing JSON De-/Serialization" do
    it "from json hash" do
      resource = Lanalytics::Model::Ressource.new_from_json(@resource_hash)
      check_resource_properties(resource)
    end

    it "from json string" do
      resource_json_str = JSON.dump(@resource_hash)
      resource = Lanalytics::Model::Ressource.new_from_json(resource_json_str)
      check_resource_properties(resource)
    end

    it "from nil should raise error" do
      expect { resource = Lanalytics::Model::Ressource.new_from_json(nil) }.to raise_error
    end

    it "to json string" do
      resource = FactoryGirl.build(:resource)
      resource_json_str = JSON.dump(resource)
      expect(resource_json_str).to be_a(String)
      expect(JSON.parse(resource_json_str)).to include('json_class' => resource.class.name, 'data' => {'type' => resource.type, 'uuid' => resource.uuid})
    end
  end

  #it "marshales correctly" do

  def check_resource_properties(actual_resource)
    expect(actual_resource).to be_a(Lanalytics::Model::Ressource)
    expect(actual_resource.type).to eq(@resource.type)
    expect(actual_resource.uuid).to eq(@resource.uuid)
  end

end