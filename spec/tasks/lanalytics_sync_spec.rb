require 'rails_helper'
require 'rake'

RAKE_TASK_NAME = 'lanalytics:sync'
describe RAKE_TASK_NAME do
  
  after(:each) do
    Neo4j::Session.query("MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r;")
    expect(Neo4j::Session.query.match(:n).pluck(:n).length).to eq(0)
  end

  before do
    Lanalytics::Application.load_tasks
  end

  describe "(services online)", pending: true do

    before do
      @course_rest_hash = FactoryGirl.attributes_for(:amqp_course)
      @user_rest_hash = FactoryGirl.attributes_for(:amqp_user)
      stub_request(:get, 'http://localhost:3300/courses.json').to_return(:body => [@course_rest_hash], :status => 200)
      stub_request(:get, 'http://localhost:3100/users.json').to_return(:body => [@user_rest_hash], :status => 200)
    end

    it 'should import the course and user' do
      expect_any_instance_of(Lanalytics::Processing::Filter::CourseDataFilter).to receive(:process).with(@course_rest_hash, kind_of(Array), kind_of(Hash))
      expect_any_instance_of(Lanalytics::Processing::Processor::Neo4jProcessor).to receive(:process).with(@course_rest_hash, kind_of(Array), kind_of(Hash))
      expect_any_instance_of(Lanalytics::Processing::Filter::ItemDataFilter).to receive(:process).with(@user_rest_hash, kind_of(Array), kind_of(Hash))
      expect_any_instance_of(Lanalytics::Processing::Processor::Neo4jProcessor).to receive(:process).with(@user_rest_hash, kind_of(Array), kind_of(Hash))
      
      invoke_rake_task

      result = Neo4j::Session.query.match(c: {:COURSE => {resource_uuid: @course_rest_hash[:id] }}).pluck(:c)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node.labels).to include(:COURSE)
      expect(expected_node.props).to include(resource_uuid: @course_rest_hash[:id])
      expect(expected_node.props).to include(title: @course_rest_hash[:title], course_code: @course_rest_hash[:course_code])
      expect(expected_node.props.keys).to include(:title, :course_code, :start_date, :end_date)

      result = Neo4j::Session.query.match(u: {:USER => {resource_uuid: @user_rest_hash[:id] }}).pluck(:u)
      expect(result.length).to eq(1)
      expected_node = result.first
      expect(expected_node.labels).to include(:COURSE)
      expect(expected_node.props).to include(resource_uuid: @user_rest_hash[:id])
      expect(expected_node.props).to include(born_at: user_rest_hash[:born_at], language: @user_rest_hash[:language])
    end

  end

  describe "(services offline)" do
    it 'should not break' do
      expect { invoke_rake_task }.not_to raise_exception
    end
  end

  def invoke_rake_task
    Rake::Task[RAKE_TASK_NAME].invoke
  end
end
