WebMock.allow_net_connect!
require 'rails_helper'
require 'rake'

RAKE_TASK_NAME = 'lanalytics:sync'
describe RAKE_TASK_NAME do
  before do
    Lanalytics::Application.load_tasks
  end

  # describe "(services online)" do

  #   before do
  #     stub_request(:any, "www.example.com")
  #   end

  # end

  describe "(services offline)" do
    it 'should not break' do
      expect { invoke_rake_task }.not_to raise_exception
    end
  end

  def invoke_rake_task
    Rake::Task[RAKE_TASK_NAME].invoke
  end
end