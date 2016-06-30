require 'spec_helper'
require 'sidekiq/testing'

describe PinboardClosedForCoursesWorker do
  before do
    ActiveJob::Base.queue_adapter = :test
    Sidekiq::Testing.fake!
  end
  let!(:qc_rule) { FactoryGirl.create :qc_rule }
  let!(:test_course) { FactoryGirl.create :test_course,
                                          { id: '00000001-3100-4444-9999-000000000002',
                                            start_date: 11.days.ago,
                                            end_date: 5.days.from_now,
                                            status: 'archive',
                                            forum_is_locked: nil
    }}
  subject { described_class.new }
  it 'should create an alert if pinboard is not locked' do
    test_course
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform test_course, qc_rule.id
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq 1
  end

  it 'should create no alert if pinboard is locked' do
    test_course.forum_is_locked = true
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform test_course, qc_rule.id
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq 0
  end
end