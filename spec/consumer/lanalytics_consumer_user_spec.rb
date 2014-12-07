require 'rails_helper'

describe LanalyticsConsumer do
  include LanalyticsConsumerSpecsHelper

  before(:each) do
    Neo4jTestHelper.clean_database
  end

  describe "for routes 'xikolo.account.user.create'" do

    before(:each) do
      @amqp_user_event_data = FactoryGirl.attributes_for(:amqp_user).with_indifferent_access
      @consumer = LanalyticsConsumer.new
      prepare_rabbitmq_stubs(@amqp_user_event_data, 'xikolo.account.user.create')
    end

    it "should create a new USER node" do
      @consumer.create

      result = Neo4j::Session.query.match(u: {:USER => {resource_uuid: @amqp_user_event_data[:id] }}).pluck(:u)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node.labels).to include(:USER)
      expect(expected_node.props).to include(resource_uuid: @amqp_user_event_data[:id])
      expect(expected_node.props.keys).to include(:language, :born_at, :affiliated)
      expect(expected_node.props.keys).to_not include(:email, :display_name, :name, :full_name, :password, :last_name, :first_name)
    end

    it "should override existing USER node" do
      
      Neo4j::Node.create({resource_uuid: @amqp_user_event_data[:id], sub_information:"SUB INFO"}, :USER)

      @consumer.create

      result = Neo4j::Session.query.match(u: {:USER => {resource_uuid: @amqp_user_event_data[:id] }}).pluck(:u)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node.labels).to include(:USER)
      expect(expected_node.props).to include(resource_uuid: @amqp_user_event_data[:id])
      expect(expected_node.props).to include(sub_information: "SUB INFO") # Old property should be still in there
      expect(expected_node.props.keys).to include(:language, :born_at, :affiliated)
      expect(expected_node.props.keys).to_not include(:email, :display_name, :name, :full_name, :password, :last_name, :first_name)
    end
  end

  describe "for routes 'xikolo.account.user.update'" do
    before(:each) do
      @amqp_user_event_data = FactoryGirl.attributes_for(:amqp_user).with_indifferent_access
      @consumer = LanalyticsConsumer.new
      prepare_rabbitmq_stubs(@amqp_user_event_data, 'xikolo.account.user.create')
      @consumer.create
    end

    it 'should update the user with new data' do

      updated_amqp_user_event_data = @amqp_user_event_data
      updated_amqp_user_event_data[:name] = 'Christoph'
      updated_amqp_user_event_data[:language] = 'es'
      prepare_rabbitmq_stubs(updated_amqp_user_event_data, 'xikolo.account.user.update')
      @consumer.update

      result = Neo4j::Session.query.match(u: {:USER => {resource_uuid: updated_amqp_user_event_data[:id] }}).pluck(:u)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node.labels).to include(:USER)
      expect(expected_node.props).to include(resource_uuid: updated_amqp_user_event_data[:id])
      expect(expected_node.props).to include(language: updated_amqp_user_event_data[:language])
      expect(expected_node.props.keys).to include(:language, :born_at, :affiliated)
      expect(expected_node.props.keys).to_not include(:email, :display_name, :name, :full_name, :password, :last_name, :first_name)
    end
  end

  describe "for routes 'xikolo.account.user.destroy'" do
    before(:each) do
      @amqp_user_event_data = FactoryGirl.attributes_for(:amqp_user).with_indifferent_access
      @consumer = LanalyticsConsumer.new
      prepare_rabbitmq_stubs(@amqp_user_event_data, 'xikolo.account.user.create')
      @consumer.create
    end

    it 'should be deleted' do

      prepare_rabbitmq_stubs(@amqp_user_event_data,'xikolo.account.user.destroy')
      @consumer.destroy

      result = Neo4j::Session.query.match(u: {:USER => {resource_uuid: @amqp_user_event_data[:id] }}).pluck(:u)
      expect(result).to be_empty
    end
  end
end
