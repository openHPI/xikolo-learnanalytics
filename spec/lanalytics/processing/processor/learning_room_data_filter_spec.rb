require 'rails_helper'

describe Lanalytics::Filter::LearningRoomDataFilter do

  before(:each) do
    @original_hash = FactoryGirl.attributes_for(:amqp_learning_room).with_indifferent_access
    @data_filter = Lanalytics::Filter::LearningRoomDataFilter.new
  end

  it 'should should create :USER resource with correct properties' do
    processed_resources = []
    @data_filter.filter(@original_hash, processed_resources)

    expect(processed_resources.length).to eq(2)
    learning_room_resource = processed_resources.first
    expect(learning_room_resource).to be_a(Lanalytics::Model::StmtResource)
    expect(learning_room_resource.type).to eq(:LEARNING_ROOM)
    expect(learning_room_resource.uuid).to eq(@original_hash[:id])
    expect(learning_room_resource.properties).to include(is_open: true, name: "Awesome Group")

    learning_room_rel = processed_resources.last
    expect(learning_room_rel).to be_a(Lanalytics::Model::ResourceRelationship)
    expect(learning_room_rel.type).to eq(:BELONGS_TO)
    expect(learning_room_rel.from_resource.uuid).to eq(@original_hash[:id])
    expect(learning_room_rel.from_resource.type).to eq(:LEARNING_ROOM)
    expect(learning_room_rel.to_resource.uuid).to eq(@original_hash[:course_id])
    expect(learning_room_rel.to_resource.type).to eq(:COURSE)
  end

  it "should not modify the original hash" do
    old_hash = @original_hash
    expect { @data_filter.filter(@original_hash, []) }.to_not raise_error
    expect(@original_hash).to be(old_hash)
    expect(@original_hash).to eq(old_hash)
  end

  # it 'should understand process as well'
  #   expect(@data_filter).to be_a(Lanalytics::Processing::Processor)respond_to?(:process)
  #   expect(@data_filter).to respond_to?(:process)
  # end

end
