# require 'rails_helper'

# describe Lanalytics::Processing::Filter::HelpdeskTicketDataFilter, :broken => true do

#   before(:each) do
#     @data_filter = Lanalytics::Processing::Filter::HelpdeskTicketDataFilter.new
#   end

#   it 'should understand the interface methods of Lanalytics::Processing::ProcessingStep' do
#     expect(@data_filter).to respond_to(:process)
#     expect(@data_filter).to respond_to(:filter)
#   end

#   it 'should do nothing when no there is no user or course set', pending: true do
#     @original_hash = FactoryBot.attributes_for(:amqp_helpdesk_ticket_no_course_and_user).with_indifferent_access
#     processed_resources = []
#     @data_filter.filter(@original_hash, processed_resources)

#     expect(processed_resources).to empty
#   end

#   it 'should create a relationship between :USER and :SYSTEM representing a user submitting a helpdesk ticket into the system', pending: true do
#     @original_hash = FactoryBot.attributes_for(:amqp_helpdesk_ticket_no_course_but_user).with_indifferent_access
#     processed_resources = []
#     @data_filter.filter(@original_hash, processed_resources)

#     expect(processed_resources).to empty
#   end

#   it 'should create a relationship between :USER and :COURSE representing a user submitting a helpdesk ticket regarding a course' do
#     @original_hash = FactoryBot.attributes_for(:amqp_helpdesk_ticket_course_and_user).with_indifferent_access
#     processed_resources = []
#     @data_filter.filter(@original_hash, processed_resources)

#     expect(processed_resources.length).to eq(1)
#     ticket_rel = processed_resources.first
#     assert_expected_ticket_relationship(ticket_rel)
#   end

#   it "should not modify the original hash" do
#     @original_hash = FactoryBot.attributes_for(:amqp_helpdesk_ticket_course_and_user).with_indifferent_access
#     old_hash = @original_hash
#     expect { @data_filter.filter(@original_hash, []) }.to_not raise_error
#     expect(@original_hash).to be(old_hash)
#     expect(@original_hash).to eq(old_hash)
#   end
  
#   describe "(Processing Registration on Rails Startup)" do
#     it "should register some main processings" do
#       internal_processing_map = Lanalytics::Processing::AmqpProcessingManager.instance.instance_eval { @processing_map }
#       expect(internal_processing_map.keys).to include(
#         'xikolo.helpdesk.ticket.create')
#     end
#   end

#   def assert_expected_ticket_relationship(ticket_relationship)
#     expect(ticket_relationship).to be_a(Lanalytics::Model::ResourceRelationship)
#     expect(ticket_relationship.type).to eq(:SUBMITTED_FEEDBACK)
#     expect(ticket_relationship.from_resource.uuid).to eq(@original_hash[:user_id])
#     expect(ticket_relationship.from_resource.type).to eq(:USER)
#     expect(ticket_relationship.to_resource.uuid).to eq(@original_hash[:course_id])
#     expect(ticket_relationship.to_resource.type).to eq(:COURSE)
#     expect(ticket_relationship.properties).to include(:title, :report, :created_at, :language, :data)
#     expect(ticket_relationship.properties).to_not include(:mail)
#   end
# end
