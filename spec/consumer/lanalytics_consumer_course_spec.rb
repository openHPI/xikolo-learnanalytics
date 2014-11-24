require 'rails_helper'

describe LanalyticsConsumer do

  before(:each) do
    Neo4jTestHelper.clean_database
  end

  describe "for routes 'xikolo.course.course.create'" do

    before(:each) do
      @amqp_course_event_data = FactoryGirl.attributes_for(:amqp_course).with_indifferent_access
      @consumer = LanalyticsConsumer.new
      allow(@consumer).to receive(:payload).and_return(@amqp_course_event_data)
      allow(@consumer).to receive(:message)
      allow(@consumer.message).to receive(:delivery_info).and_return({routing_key: 'xikolo.course.course.create'})
    end

    it "should create a new COURSE node" do
      @consumer.create

      result = Neo4j::Session.query.match(c: {:COURSE => {resource_uuid: @amqp_course_event_data[:id] }}).pluck(:c)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node.labels).to include(:COURSE)
      expect(expected_node.props).to include(resource_uuid: @amqp_course_event_data[:id])
      expect(expected_node.props).to include(title: @amqp_course_event_data[:title], course_code:@amqp_course_event_data[:course_code])
      expect(expected_node.props.keys).to include(:title, :course_code, :start_date, :end_date)
    end

    it "should override existing COURSE node" do
      
      Neo4j::Node.create({resource_uuid: @amqp_course_event_data[:id], sub_description:"COURSE SUB DESCRIPTION"}, :COURSE)

      @consumer.create

      result = Neo4j::Session.query.match(c: {:COURSE => {resource_uuid: @amqp_course_event_data[:id] }}).pluck(:c)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node.labels).to include(:COURSE)
      expect(expected_node.props).to include(resource_uuid: @amqp_course_event_data[:id])
      expect(expected_node.props).to include(title: @amqp_course_event_data[:title], course_code: @amqp_course_event_data[:course_code])
      expect(expected_node.props).to include(sub_description: "COURSE SUB DESCRIPTION") # Old property should be still in there
    end
  end

  describe "for routes 'xikolo.course.course.update'" do
    before(:each) do
      @amqp_course_event_data = FactoryGirl.attributes_for(:amqp_course).with_indifferent_access
      @consumer = LanalyticsConsumer.new
      allow(@consumer).to receive(:payload).and_return(@amqp_course_event_data)
      allow(@consumer).to receive(:message)
      allow(@consumer.message).to receive(:delivery_info).and_return({routing_key: 'xikolo.course.course.create'})
      @consumer.create
    end

    it 'should update the course with new data' do

      updated_amqp_course_event_data = @amqp_course_event_data
      updated_amqp_course_event_data[:title] = 'Updated Awesome Prof. Meinel Course'
      allow(@consumer).to receive(:payload).and_return(updated_amqp_course_event_data)
      allow(@consumer).to receive(:message)
      allow(@consumer.message).to receive(:delivery_info).and_return({routing_key: 'xikolo.course.course.update'})
      
      @consumer.update

      result = Neo4j::Session.query.match(c: {:COURSE => {resource_uuid: updated_amqp_course_event_data[:id] }}).pluck(:c)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node.labels).to include(:COURSE)
      expect(expected_node.props).to include(resource_uuid: updated_amqp_course_event_data[:id])
      expect(expected_node.props).to include(title: updated_amqp_course_event_data[:title], course_code:updated_amqp_course_event_data[:course_code])
      expect(expected_node.props.keys).to include(:title, :course_code, :start_date, :end_date)
    end
  end

  describe "for routes 'xikolo.course.course.destroy'" do
    before(:each) do
      @amqp_course_event_data = FactoryGirl.attributes_for(:amqp_course).with_indifferent_access
      @consumer = LanalyticsConsumer.new
      allow(@consumer).to receive(:payload).and_return(@amqp_course_event_data)
      allow(@consumer).to receive(:message)
      allow(@consumer.message).to receive(:delivery_info).and_return({routing_key: 'xikolo.course.course.create'})
      @consumer.create
    end

    it 'should be deleted' do

      allow(@consumer).to receive(:payload).and_return(@amqp_course_event_data)
      allow(@consumer).to receive(:message)
      allow(@consumer.message).to receive(:delivery_info).and_return({routing_key: 'xikolo.course.course.destroy'})
      @consumer.destroy

      result = Neo4j::Session.query.match(c: {:COURSE => {resource_uuid: @amqp_course_event_data[:id] }}).pluck(:c)
      expect(result).to be_empty
    end
  end
end
