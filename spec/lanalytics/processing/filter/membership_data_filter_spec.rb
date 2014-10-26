require 'rails_helper'

describe Lanalytics::Processing::Filter::MembershipDataFilter do

  describe 'Instantiation' do

    it 'should correctly parse resource type and key' do
      data_filter = Lanalytics::Processing::Filter::MembershipDataFilter.new(:user_id, :learning_room_id)
      expect(data_filter.instance_eval { @from_resource_id_key }).to eq(:user_id)
      expect(data_filter.instance_eval { @from_resource_type }).to eq(:USER)
      expect(data_filter.instance_eval { @to_resource_id_key }).to eq(:learning_room_id)
      expect(data_filter.instance_eval { @to_resource_id_key }).to eq(:learning_room_id)

      # Is the standard connection
      expect(data_filter.instance_eval { @relationship_type }).to eq(:BELONGS_TO)
    end

    it 'should raise an error when no type found' do
      expect { Lanalytics::Processing::Filter::MembershipDataFilter.new(:id, :learning_room_id) }.to raise_error(ArgumentError)
      expect { Lanalytics::Processing::Filter::MembershipDataFilter.new(:_id, :learning_room_id) }.to raise_error(ArgumentError)
      expect { Lanalytics::Processing::Filter::MembershipDataFilter.new(nil, :learning_room_id) }.to raise_error(ArgumentError)
      expect { Lanalytics::Processing::Filter::MembershipDataFilter.new(:user_id, :asdasdasdasd) }.to raise_error(ArgumentError)
      expect { Lanalytics::Processing::Filter::MembershipDataFilter.new(:user_id, nil) }.to raise_error(ArgumentError)
    end

  end

  describe '(Processing with default relationship type)' do

    before(:each) do
      @original_hash = FactoryGirl.attributes_for(:amqp_learning_room_membership).with_indifferent_access
      @data_filter = Lanalytics::Processing::Filter::MembershipDataFilter.new(:user_id, :learning_room_id)
    end

    it 'should should create :USER resource with correct properties' do
      processed_resources = []
      @data_filter.filter(@original_hash, processed_resources)

      expect(processed_resources.length).to eq(1)
      learning_room_rel = processed_resources.last
      expect(learning_room_rel).to be_a(Lanalytics::Model::ResourceRelationship)
      expect(learning_room_rel.type).to eq(:BELONGS_TO)
      expect(learning_room_rel.from_resource.uuid).to eq(@original_hash[:user_id])
      expect(learning_room_rel.from_resource.type).to eq(:USER)
      expect(learning_room_rel.to_resource.uuid).to eq(@original_hash[:learning_room_id])
      expect(learning_room_rel.to_resource.type).to eq(:LEARNING_ROOM)
    end

    it "should not modify the original hash" do
      old_hash = @original_hash
      expect { @data_filter.filter(@original_hash, []) }.to_not raise_error
      expect(@original_hash).to be(old_hash)
      expect(@original_hash).to eq(old_hash)
    end
  end

  # it 'should understand process as well'
  #   expect(@data_filter).to be_a(Lanalytics::Processing::Processor)respond_to?(:process)
  #   expect(@data_filter).to respond_to?(:process)
  # end

  describe '(Processing with custom relationship type)' do

    it 'should should create :USER resource with correct properties' do
      original_hash = FactoryGirl.attributes_for(:amqp_learning_room_membership).with_indifferent_access
      data_filter = Lanalytics::Processing::Filter::MembershipDataFilter.new(:user_id, :learning_room_id, :JOINED)

      processed_resources = []
      data_filter.filter(original_hash, processed_resources)

      expect(processed_resources.length).to eq(1)
      learning_room_rel = processed_resources.last
      expect(learning_room_rel).to be_a(Lanalytics::Model::ResourceRelationship)
      expect(learning_room_rel.type).to eq(:JOINED)
      expect(learning_room_rel.from_resource.uuid).to eq(original_hash[:user_id])
      expect(learning_room_rel.from_resource.type).to eq(:USER)
      expect(learning_room_rel.to_resource.uuid).to eq(original_hash[:learning_room_id])
      expect(learning_room_rel.to_resource.type).to eq(:LEARNING_ROOM)
    end
  end
end
