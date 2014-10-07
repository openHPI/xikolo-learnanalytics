require 'rails_helper'

RSpec.describe Lanalytics::Model::Ressource do

  it "from json hash" do
    resource = Lanalytics::Model::Ressource.new_from_json(example_item_json_hash)
    expect(resource).to be_instance_of(Lanalytics::Model::Ressource)
    expect(resource.type).to eq("Item")
    expect(resource.uuid).to eq("00000003-3100-4444-9999-000000000003")
  end

  it "from json string" do
    resource = Lanalytics::Model::Ressource.new_from_json(JSON.dump(example_item_json_hash))
    expect(resource).to be_instance_of(Lanalytics::Model::Ressource)
    expect(resource.type).to eq("Item")
    expect(resource.uuid).to eq("00000003-3100-4444-9999-000000000003")
  end

  it "marshales correctly" do
    
  end

  def example_item_json_hash
    return {
      "type" => "Item",
      "uuid" => "00000003-3100-4444-9999-000000000003"
    }
  end


end