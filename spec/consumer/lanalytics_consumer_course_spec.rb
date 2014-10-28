require 'rails_helper'

describe LanalyticsConsumer do

  after(:each) do
    Neo4j::Session.query("MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r;")
    expect(Neo4j::Session.query.match(:n).pluck(:n).length).to eq(0)
  end

  describe "for routes 'xikolo.course.enrollment.create'" do

    before(:each) do
      @amqp_enrollment_event_data = FactoryGirl.attributes_for(:amqp_enrollment).with_indifferent_access
      @consumer = LanalyticsConsumer.new
      allow(@consumer).to receive(:payload).and_return(@amqp_enrollment_event_data)
      allow(@consumer).to receive(:message)
      allow(@consumer.message).to receive(:delivery_info).and_return({routing_key: 'xikolo.course.enrollment.create'})
    end

    it "should create a new enrollment relationship between newly created USER and COURSE nodes" do
      @consumer.create

      result = Neo4j::Session.query.match(c: {:COURSE => {resource_uuid: @amqp_enrollment_event_data[:course_id] }}).pluck(:c)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node[:resource_uuid]).to eq(@amqp_enrollment_event_data[:course_id])
      expect(expected_node.labels).to include(:COURSE)

      result = Neo4j::Session.query.match(u: {:USER => {resource_uuid: @amqp_enrollment_event_data[:user_id] }}).pluck(:u)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node[:resource_uuid]).to eq(@amqp_enrollment_event_data[:user_id])
      expect(expected_node.labels).to include(:USER)

      result = Neo4j::Session.query(%{
        MATCH (u:USER {resource_uuid: '#{@amqp_enrollment_event_data[:user_id]}'})-[e:ENROLLED]->(c:COURSE {resource_uuid: '#{@amqp_enrollment_event_data[:course_id]}'})
        RETURN e
      })
      expect(result.to_a.length).to eq(1)
      expected_enrollemnt_relationship = result.first.e
      puts "#{expected_enrollemnt_relationship.instance_variables}"
      expect(expected_enrollemnt_relationship.rel_type).to eq(:ENROLLED)
      expect(expected_enrollemnt_relationship[:role]).to eq(@amqp_enrollment_event_data[:role])
    end

    it "should create a new enrollment relationship between the existing USER and COURSE nodes" do
      
      Neo4j::Node.create({resource_uuid: @amqp_enrollment_event_data[:course_id], other_prop:"other_prop_value"}, :COURSE)
      Neo4j::Node.create({resource_uuid: @amqp_enrollment_event_data[:user_id], other_prop:"other_prop_value"}, :USER)

      @consumer.create

      result = Neo4j::Session.query.match(c: {:COURSE => {resource_uuid: @amqp_enrollment_event_data[:course_id] }}).pluck(:c)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node[:other_prop]).to_not be_nil

      result = Neo4j::Session.query.match(u: {:USER => {resource_uuid: @amqp_enrollment_event_data[:user_id] }}).pluck(:u)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node[:other_prop]).to_not be_nil

      result = Neo4j::Session.query(%{
        MATCH (u:USER {resource_uuid: '#{@amqp_enrollment_event_data[:user_id]}'})-[e:ENROLLED]->(c:COURSE {resource_uuid: '#{@amqp_enrollment_event_data[:course_id]}'})
        RETURN e
      })
      expect(result.to_a.length).to eq(1)
      expected_enrollemnt_relationship = result.first.e
      puts "#{expected_enrollemnt_relationship.instance_variables}"
      expect(expected_enrollemnt_relationship.rel_type).to eq(:ENROLLED)
      expect(expected_enrollemnt_relationship[:role]).to eq(@amqp_enrollment_event_data[:role])
    end

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
end
