require 'rails_helper'

describe LanalyticsConsumer do

  after(:each) do
    Neo4j::Session.query("MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r;")
    expect(Neo4j::Session.query.match(:n).pluck(:n).length).to eq(0)
  end

  describe "for routes 'xikolo.web.event.create'" do

    before(:each) do
      @amqp_exp_stmt_data = FactoryGirl.attributes_for(:amqp_exp_stmt).with_indifferent_access
      @consumer = LanalyticsConsumer  .new
      allow(@consumer).to receive(:payload).and_return(@amqp_exp_stmt_data)
      allow(@consumer).to receive(:message).and_return(double('message'))
      allow(@consumer.message).to receive(:delivery_info).and_return({routing_key: 'xikolo.web.event.create'})
    end

    it "should create a new enrollment relationship between newly created USER and COURSE nodes" do
      @consumer.handle_user_event

      result = Neo4j::Session.query.match(i: {:ITEM => {resource_uuid: @amqp_exp_stmt_data[:resource][:uuid]  }}).pluck(:i)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node[:resource_uuid]).to eq(@amqp_exp_stmt_data[:resource][:uuid])
      expect(expected_node.labels).to include(:ITEM)

      result = Neo4j::Session.query.match(u: {:USER => {resource_uuid: @amqp_exp_stmt_data[:user][:uuid] }}).pluck(:u)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node[:resource_uuid]).to eq(@amqp_exp_stmt_data[:user][:uuid])
      expect(expected_node.labels).to include(:USER)

      result = Neo4j::Session.query(%{
        MATCH (u:USER {resource_uuid: '#{@amqp_exp_stmt_data[:user][:uuid]}'})-[e:#{@amqp_exp_stmt_data[:verb][:type]}]->(c:ITEM {resource_uuid: '#{@amqp_exp_stmt_data[:resource][:uuid]}'})
        RETURN e
      })
      expect(result.to_a.length).to eq(1)
      expected_enrollemnt_relationship = result.first.e
      expect(expected_enrollemnt_relationship.rel_type).to eq(@amqp_exp_stmt_data[:verb][:type])
      expect(expected_enrollemnt_relationship[:timestamp]).to eq(@amqp_exp_stmt_data[:timestamp])
      expect(expected_enrollemnt_relationship[:with_result]).to be_nil
      expect(expected_enrollemnt_relationship[:context_currentTime]).to_not be_nil
      expect(expected_enrollemnt_relationship[:context_currentSpeed]).to_not be_nil
    end

  end
end
