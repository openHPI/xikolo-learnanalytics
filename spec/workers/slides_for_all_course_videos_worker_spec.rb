require 'spec_helper'
require 'sidekiq/testing'

describe SlidesForAllCourseVideosWorker do
  before do
    ActiveJob::Base.queue_adapter = :test
    Sidekiq::Testing.fake!
  end
  let!(:qc_rule) { FactoryGirl.create :qc_rule }
  let!(:test_course) { FactoryGirl.create :test_course,
                                          { id: '00000001-3100-4444-9999-000000000002',
      start_date: DateTime.now,
      end_date: 5.days.from_now,
      status: 'preparation',
      forum_is_locked: nil
  }}
  let!(:test_course2) { FactoryGirl.create :test_course,
                                          { id: '00000001-3100-4444-9999-000000000003',
      start_date: DateTime.now,
      end_date: 5.days.from_now,
      status: 'preparation',
      forum_is_locked: nil
  }}

  before do
    Stub.request(
      :course, :get, '/items',
      query: { course_id: test_course.id, content_type: 'video' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000004', content_id: '00000001-3100-4444-9999-000000000004' }
    ])
    Stub.request(
      :course, :get, '/items',
      query: { course_id: test_course2.id, content_type: 'video' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000003', content_id: '00000001-3100-4444-9999-000000000003' }
    ])
    Stub.request(
      :video, :get, '/videos/00000001-3100-4444-9999-000000000004'
    ).to_return Stub.json(
      id: '00000001-3100-4444-9999-000000000004',
      thumbnail_archive_id: nil
    )
    Stub.request(
      :video, :get, '/videos/00000001-3100-4444-9999-000000000003'
    ).to_return Stub.json(
      id: '00000001-3100-4444-9999-000000000003',
      thumbnail_archive_id: 'abc'
    )
  end

  subject { described_class.new }

  it 'should create an alert if slides are not present' do
    test_course
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform test_course, qc_rule.id
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq 1
  end

  it 'should not create an alert if slides are present' do
    test_course2
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform test_course2, qc_rule.id
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq 0
  end
end
