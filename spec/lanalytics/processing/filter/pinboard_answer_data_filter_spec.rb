# require 'rails_helper'

# describe Lanalytics::Processing::Filter::PinboardAnswerDataFilter, :broken => true do

#   before(:each) do
#     @data_filter = Lanalytics::Processing::Filter::PinboardAnswerDataFilter.new
#     @original_hash = FactoryGirl.attributes_for(:amqp_pinboard_answer).with_indifferent_access
#   end

#   it 'should understand the interface methods of Lanalytics::Processing::ProcessingStep' do
#     expect(@data_filter).to respond_to(:process)
#     expect(@data_filter).to respond_to(:filter)
#   end

#   it 'should create :ANSWER resource and a relationship to :USER and :QUESTION' do
#     processed_resources = []
#     @data_filter.filter(@original_hash, processed_resources)

#     expect(processed_resources.length).to eq(3)

#     assert_expected_question_resource(processed_resources.first)

#     user_question_rel = processed_resources[1]
#     expect(user_question_rel).to be_a(Lanalytics::Model::ResourceRelationship)
#     expect(user_question_rel.type).to eq(:POSTED_ANSWER)
#     expect(user_question_rel.from_resource.uuid).to eq(@original_hash[:user_id])
#     expect(user_question_rel.from_resource.type).to eq(:USER)
#     expect(user_question_rel.to_resource.uuid).to eq(@original_hash[:id])
#     expect(user_question_rel.to_resource.type).to eq(:ANSWER)

#     question_belongs_to_rel = processed_resources[2]
#     expect(question_belongs_to_rel).to be_a(Lanalytics::Model::ResourceRelationship)
#     expect(question_belongs_to_rel.type).to eq(:BELONGS_TO)
#     expect(question_belongs_to_rel.from_resource.uuid).to eq(@original_hash[:id])
#     expect(question_belongs_to_rel.from_resource.type).to eq(:ANSWER)
#     expect(question_belongs_to_rel.to_resource.uuid).to eq(@original_hash[:question_id])
#     expect(question_belongs_to_rel.to_resource.type).to eq(:QUESTION)   
#   end

#   it "should not modify the original hash" do
#     old_hash = @original_hash
#     expect { @data_filter.filter(@original_hash, []) }.to_not raise_error
#     expect(@original_hash).to be(old_hash)
#     expect(@original_hash).to eq(old_hash)
#   end

#    describe "(Processing Registration on Rails Startup)" do
#     it "should register some main processings" do
#       internal_processing_map = Lanalytics::Processing::AmqpProcessingManager.instance.instance_eval { @processing_map }
#       expect(internal_processing_map.keys).to include(
#         'xikolo.pinboard.question.create')
#     end
#   end

#   def assert_expected_question_resource(question_resource)
#     expect(question_resource).to be_a(Lanalytics::Model::StmtResource)
#     expect(question_resource.type).to eq(:ANSWER)
#     expect(question_resource.uuid).to eq(@original_hash[:id])
#     expect(question_resource.properties).to include(text: @original_hash[:text])
#     expect(question_resource.properties).to include(:text, :created_at, :updated_at)
#     expect(question_resource.properties).to_not include(:id, :question_id, :votes, :file_id, :user_id)
#   end
# end
