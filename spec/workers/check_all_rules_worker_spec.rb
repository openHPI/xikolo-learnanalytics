require 'spec_helper'

describe CheckAllRulesWorker do
  before { Sidekiq::Testing.fake! }

  it 'should be processed with high priority' do
    expect(CheckAllRulesWorker).to be_processed_in :high
  end

  before do
    Stub.service(
      :course,
      courses_url: '/courses'
    )
    Stub.request(
      :course, :get, '/courses',
      query: { affiliated: 'true', public: 'true' }
    ).to_return Stub.json([
      {id: 1, external_course_url: nil},
      {id: 2, external_course_url: nil},
      {id: 3, external_course_url: 'http://coursera.org/wat'}
    ])
  end

  it 'should enqueue a worker to check all global rules' do
    expect {
      CheckAllRulesWorker.new.perform
    }.to change(CheckGlobalRulesWorker.jobs, :size).by(1)
  end

  it 'should enqueue a worker to check rules for each non-external course' do
    expect {
      CheckAllRulesWorker.new.perform
    }.to change(CheckCourseRulesWorker.jobs, :size).by(2)
  end
end
