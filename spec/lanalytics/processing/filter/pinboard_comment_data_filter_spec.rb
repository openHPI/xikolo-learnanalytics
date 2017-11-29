# require 'rails_helper'

# describe Lanalytics::Processing::Filter::PinboardCommentDataFilter, :broken => true do

#   before(:each) do
#     @data_filter = Lanalytics::Processing::Filter::PinboardCommentDataFilter.new
#   end

#   it 'should understand the interface methods of Lanalytics::Processing::ProcessingStep' do
#     expect(@data_filter).to respond_to(:process)
#     expect(@data_filter).to respond_to(:filter)
#   end

#   it 'should create a relationship between :USER and :QUESTION representing a user commenting a question' do
#     @original_hash = FactoryBot.attributes_for(:amqp_pinboard_question_comment).with_indifferent_access
#     processed_resources = []
#     @data_filter.filter(@original_hash, processed_resources)

#     expect(processed_resources.length).to eq(1)

#     commenting_rel = processed_resources.first
#     assert_expected_commenting_relationship(commenting_rel)
#     expect(commenting_rel.to_resource.type).to eq(:QUESTION)
#   end

#   it 'should create a relationship between :USER and :ANSWER representing a user commenting a question' do
#     @original_hash = FactoryBot.attributes_for(:amqp_pinboard_answer_comment).with_indifferent_access
#     processed_resources = []
#     @data_filter.filter(@original_hash, processed_resources)

#     expect(processed_resources.length).to eq(1)

#     commenting_rel = processed_resources.first
#     assert_expected_commenting_relationship(commenting_rel)
#     expect(commenting_rel.to_resource.type).to eq(:ANSWER)
#   end

#   it "should not modify the original hash" do
#     @original_hash = FactoryBot.attributes_for(:amqp_pinboard_question_comment).with_indifferent_access
#     old_hash = @original_hash
#     expect { @data_filter.filter(@original_hash, []) }.to_not raise_error
#     expect(@original_hash).to be(old_hash)
#     expect(@original_hash).to eq(old_hash)
#   end
  
#   describe "(Processing Registration on Rails Startup)" do
#     it "should register some main processings" do
#       internal_processing_map = Lanalytics::Processing::AmqpProcessingManager.instance.instance_eval { @processing_map }
#       expect(internal_processing_map.keys).to include(
#         'xikolo.pinboard.comment.create')
#     end
#   end

#   def assert_expected_commenting_relationship(commenting_relationship)
#     expect(commenting_relationship).to be_a(Lanalytics::Model::ResourceRelationship)
#     expect(commenting_relationship.type).to eq(:COMMENTED)
#     expect(commenting_relationship.from_resource.uuid).to eq(@original_hash[:user_id])
#     expect(commenting_relationship.from_resource.type).to eq(:USER)
#     expect(commenting_relationship.to_resource.uuid).to eq(@original_hash[:commentable_id])
#     expect(commenting_relationship.properties).to include(:text, :created_at, :updated_at)
#   end
# end
