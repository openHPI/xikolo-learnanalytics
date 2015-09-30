require 'rails_helper'

describe LanalyticsConsumer do
  if Lanalytics::Processing::DatasourceManager.datasource_exists?('exp_graph_schema_neo4j')

    include LanalyticsConsumerSpecsHelper
    
    before(:each) do
      Neo4jTestHelper.clean_database
    end

    describe "for routes 'xikolo.course.enrollment.create'" do

      before(:each) do
        @amqp_enrollment_event_data = FactoryGirl.attributes_for(:amqp_enrollment).with_indifferent_access
        @consumer = LanalyticsConsumer.new
        prepare_rabbitmq_stubs(@amqp_enrollment_event_data, 'xikolo.course.enrollment.create')
      end

      it "should create a new enrollment relationship between newly created USER and COURSE nodes" do
        @consumer.create

        result = Neo4j::Session.query.match(c: {COURSE: {resource_uuid: @amqp_enrollment_event_data[:course_id]}}).pluck(:c)
        expect(result.length).to eq(1)
        expected_node = result.first
        expect(expected_node[:resource_uuid]).to eq(@amqp_enrollment_event_data[:course_id])
        expect(expected_node.labels).to include(:COURSE)

        result = Neo4j::Session.query.match(u: {USER: {resource_uuid: @amqp_enrollment_event_data[:user_id]}}).pluck(:u)

        expect(result.length).to eq(1)
        expected_node = result.first
        expect(expected_node[:resource_uuid]).to eq(@amqp_enrollment_event_data[:user_id])
        expect(expected_node.labels).to include(:USER)

        result = Neo4j::Session.query(%{
          MATCH (u:USER {resource_uuid: '#{@amqp_enrollment_event_data[:user_id]}'})-[e:ENROLLED]->(c:COURSE {resource_uuid: '#{@amqp_enrollment_event_data[:course_id]}'})
          RETURN e
        })
        expect(result.to_a.length).to eq(1)
        expected_enrollment_relationship = result.first.e
        expect(expected_enrollment_relationship.rel_type).to eq(:ENROLLED)
        expect(expected_enrollment_relationship[:role]).to eq(@amqp_enrollment_event_data[:role])
      end

      it "should create a new enrollment relationship between the existing USER and COURSE nodes" do
        
        Neo4j::Node.create({resource_uuid: @amqp_enrollment_event_data[:course_id], other_prop:"other_prop_value"}, :COURSE)
        Neo4j::Node.create({resource_uuid: @amqp_enrollment_event_data[:user_id], other_prop:"other_prop_value"}, :USER)

        @consumer.create

        result = Neo4j::Session.query.match(c: {COURSE: {resource_uuid: @amqp_enrollment_event_data[:course_id]}}).pluck(:c)
        expect(result.length).to eq(1)
        expected_node = result.first
        expect(expected_node[:other_prop]).to_not be_nil

        result = Neo4j::Session.query.match(u: {USER: {resource_uuid: @amqp_enrollment_event_data[:user_id]}}).pluck(:u)
        expect(result.length).to eq(1)
        expected_node = result.first
        expect(expected_node[:other_prop]).to_not be_nil

        result = Neo4j::Session.query(%{
          MATCH (u:USER {resource_uuid: '#{@amqp_enrollment_event_data[:user_id]}'})-[e:ENROLLED]->(c:COURSE {resource_uuid: '#{@amqp_enrollment_event_data[:course_id]}'})
          RETURN e
        })
        expect(result.to_a.length).to eq(1)
        expected_enrollemnt_relationship = result.first.e
        expect(expected_enrollemnt_relationship.rel_type).to eq(:ENROLLED)
        expect(expected_enrollemnt_relationship[:role]).to eq(@amqp_enrollment_event_data[:role])
      end
    end

    describe "for routes 'xikolo.course.enrollment.destroy'" do
      before(:each) do
        @amqp_enrollment_event_data = FactoryGirl.attributes_for(:amqp_enrollment).with_indifferent_access
        @consumer = LanalyticsConsumer.new
        prepare_rabbitmq_stubs(@amqp_enrollment_event_data, 'xikolo.course.enrollment.create')
        @consumer.create
      end

      it 'should be deleted' do
        @amqp_enrollment_event_data = FactoryGirl.attributes_for(:amqp_enrollment).with_indifferent_access
        prepare_rabbitmq_stubs(@amqp_enrollment_event_data, 'xikolo.course.enrollment.destroy')
        @consumer.destroy

        result = Neo4j::Session.query(%{
          MATCH (u:USER {resource_uuid: '#{@amqp_enrollment_event_data[:user_id]}'})-[e:ENROLLED]->(c:COURSE {resource_uuid: '#{@amqp_enrollment_event_data[:course_id]}'})
          RETURN e
        })

        expect(result.to_a.length).to eq(1)
        expected_enrollment_relationship = result.first.e
        expect(expected_enrollment_relationship.rel_type).to eq(:ENROLLED)
        expect(expected_enrollment_relationship[:role]).to eq(@amqp_enrollment_event_data[:role])

        result = Neo4j::Session.query(%{
          MATCH (u:USER {resource_uuid: '#{@amqp_enrollment_event_data[:user_id]}'})-[e:UN_ENROLLED]->(c:COURSE {resource_uuid: '#{@amqp_enrollment_event_data[:course_id]}'})
          RETURN e
        })

        expect(result.to_a.length).to eq(1)
        expected_unenrollment_relationship = result.first.e
        expect(expected_unenrollment_relationship.rel_type).to eq(:UN_ENROLLED)
        expect(expected_unenrollment_relationship[:role]).to eq(@amqp_enrollment_event_data[:role])
      end
    end

  end
end