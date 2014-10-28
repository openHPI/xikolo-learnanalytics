require 'rails_helper'

describe Lanalytics::Processing::Filter::PinboardQuestionDataFilter do

  before(:each) do
    @data_filter = Lanalytics::Processing::Filter::PinboardQuestionDataFilter.new
  end

  it 'should understand the interface methods of Lanalytics::Processing::ProcessingStep' do
    expect(@data_filter).to respond_to(:process)
    expect(@data_filter).to respond_to(:filter)
  end

  describe '(Connection to :COURSE resource)' do
    before(:each) do
      @original_hash = FactoryGirl.attributes_for(:amqp_pinboard_question).with_indifferent_access
    end
    
    it 'should create :QUESTION resource, a relationship to :USER and :COURSE' do
      processed_resources = []
      @data_filter.filter(@original_hash, processed_resources)

      expect(processed_resources.length).to eq(3)

      assert_expected_question_resource(processed_resources.first)

      user_question_rel = processed_resources[1]
      expect(user_question_rel).to be_a(Lanalytics::Model::ResourceRelationship)
      expect(user_question_rel.type).to eq(:POSTED)
      expect(user_question_rel.from_resource.uuid).to eq(@original_hash[:user_id])
      expect(user_question_rel.from_resource.type).to eq(:USER)
      expect(user_question_rel.to_resource.uuid).to eq(@original_hash[:id])
      expect(user_question_rel.to_resource.type).to eq(:QUESTION)

      question_belongs_to_rel = processed_resources[2]
      expect(question_belongs_to_rel).to be_a(Lanalytics::Model::ResourceRelationship)
      expect(question_belongs_to_rel.type).to eq(:BELONGS_TO)
      expect(question_belongs_to_rel.from_resource.uuid).to eq(@original_hash[:id])
      expect(question_belongs_to_rel.from_resource.type).to eq(:QUESTION)
      expect(question_belongs_to_rel.to_resource.uuid).to eq(@original_hash[:course_id])
      expect(question_belongs_to_rel.to_resource.type).to eq(:COURSE)    
    end


    it "should not modify the original hash" do
      old_hash = @original_hash
      expect { @data_filter.filter(@original_hash, []) }.to_not raise_error
      expect(@original_hash).to be(old_hash)
      expect(@original_hash).to eq(old_hash)
    end
  end


  describe '(Connection to :LEARNING_ROOM resource)' do

    it 'should create :QUESTION resource, a relationship to :USER and :LEARNING_ROOM' do
      @original_hash = FactoryGirl.attributes_for(:amqp_pinboard_learning_room_question).with_indifferent_access

      processed_resources = []
      
      @data_filter.filter(@original_hash, processed_resources)

      expect(processed_resources.length).to eq(3)

      assert_expected_question_resource(processed_resources.first)

      user_question_rel = processed_resources[1]
      expect(user_question_rel).to be_a(Lanalytics::Model::ResourceRelationship)
      expect(user_question_rel.type).to eq(:POSTED)
      expect(user_question_rel.from_resource.uuid).to eq(@original_hash[:user_id])
      expect(user_question_rel.from_resource.type).to eq(:USER)
      expect(user_question_rel.to_resource.uuid).to eq(@original_hash[:id])
      expect(user_question_rel.to_resource.type).to eq(:QUESTION)

      question_belongs_to_rel = processed_resources[2]
      expect(question_belongs_to_rel).to be_a(Lanalytics::Model::ResourceRelationship)
      expect(question_belongs_to_rel.type).to eq(:BELONGS_TO)
      expect(question_belongs_to_rel.from_resource.uuid).to eq(@original_hash[:id])
      expect(question_belongs_to_rel.from_resource.type).to eq(:QUESTION)
      expect(question_belongs_to_rel.to_resource.uuid).to eq(@original_hash[:learning_room_id])
      expect(question_belongs_to_rel.to_resource.type).to eq(:LEARNING_ROOM)  
    end
  end

   describe "(Processing Registration on Rails Startup)" do
    it "should register some main processings" do
      internal_processing_map = Lanalytics::Processing::AmqpProcessingManager.instance.instance_eval { @processing_map }
      expect(internal_processing_map.keys).to include(
        'xikolo.pinboard.question.create')
    end
  end

  def assert_expected_question_resource(question_resource)
    expect(question_resource).to be_a(Lanalytics::Model::StmtResource)
    expect(question_resource.type).to eq(:QUESTION)
    expect(question_resource.uuid).to eq(@original_hash[:id])
    expect(question_resource.properties).to include(title: "Test Question 0")
    expect(question_resource.properties).to include(text: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua")
    expect(question_resource.properties).to include(:sticky, :deleted, :closed, :discussion_flag, :created_at, :updated_at, :user_tags)
    expect(question_resource.properties).to_not include(:id, :course_id, :learning_room_id, :votes, :views, :file_id, :accepted_answer_id, :implicit_tags, :answer_count, :comment_count, :answer_comment_count, :video_timestamp, :video_id, :user_id)
  end
end
