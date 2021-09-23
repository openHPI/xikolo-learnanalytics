# frozen_string_literal: true

require 'spec_helper'

describe CheckAllRulesWorker do
  before do
    Sidekiq::Testing.fake!

    Stub.request(:course, :get)
      .to_return Stub.json(courses_url: '/courses')
    Stub.request(
      :course, :get, '/courses',
      query: {groups: 'any', public: 'true'}
    ).to_return Stub.json([
      {id: 1, external_course_url: nil},
      {id: 2, external_course_url: nil},
      {id: 3, external_course_url: 'http://coursera.org/wat'},
    ])
  end

  it 'is processed with high priority' do
    expect(described_class).to be_processed_in :high
  end

  it 'enqueues a worker to check all global rules' do
    expect do
      described_class.new.perform
    end.to change(CheckGlobalRulesWorker.jobs, :size).by(1)
  end

  it 'enqueues a worker to check rules for each non-external course' do
    expect do
      described_class.new.perform
    end.to change(CheckCourseRulesWorker.jobs, :size).by(2)
  end
end
