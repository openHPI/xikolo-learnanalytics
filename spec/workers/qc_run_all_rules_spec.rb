require 'spec_helper'
require 'sidekiq/testing'

describe QcRunAllRules do
  before do
    ActiveJob::Base.queue_adapter = :test
    Sidekiq::Testing.fake!

  end
  let(:qc_rule) { FactoryGirl.create :qc_rule }
  let(:qc_alert) { FactoryGirl.create :qc_alert, qc_rule_id: qc_rule.id }

  before do
    Stub.request(
      :course, :get, '/courses',
      query: { affiliated: 'true', public: 'true', page: '1', per_page: '50' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000001', course_code: 'testcourse' }
    ])
    Stub.request(
      :course, :get, '/enrollments'
    ).to_return Stub.json([
      { id: '00000001-3100-5555-9999-000000000008' }
    ])
  end

  subject { described_class.new.perform}

  it 'should be processed in right queue' do
    expect(QcRunAllRules).to be_processed_in :high
  end

  it 'should enqueue a job' do
    expect {
      QcRunAllRules.perform_async
    }.to change(QcRunAllRules.jobs, :size).by(1)
  end

  it 'should initialize' do
    subject
  end
=begin
  it 'should call correct worker class' do
    expect(qc_rule.worker).to eq('PinboardActivityWorker')
    expect(PinboardActivityWorker).to receive(:perform)
    qc_rule
    QcRunAllRules.new.perform
    subject
  end
=end
end
