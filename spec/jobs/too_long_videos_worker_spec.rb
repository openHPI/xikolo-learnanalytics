require 'spec_helper'
require 'sidekiq/testing'

describe TooLongVideosWorker do
  before do
    ActiveJob::Base.queue_adapter = :test
    Sidekiq::Testing.fake!
  end
  let!(:qc_rule2) { FactoryGirl.create :qc_rule }
  let!(:test_course) { FactoryGirl.create :test_course,
                                          {id: '00000001-3100-4444-9999-000000000002',
      start_date: 11.days.ago,
          end_date: 5.days.from_now,
          status: 'active' }}

  let!(:test_course_over) { FactoryGirl.create :test_course,
                                          {id: '00000001-3100-4444-9999-000000000002',
      start_date: 11.days.ago,
          end_date: 1.day.ago,
          status: 'active' }}
  let!(:test_course2) { FactoryGirl.create :test_course,
                                           {id: '00000001-3100-4444-9999-000000000003',
      start_date: 11.days.ago,
          end_date: 5.days.from_now,
          status: 'active' }}
  let(:qc_alert_open) { FactoryGirl.create :qc_alert, {qc_rule_id: qc_rule2.id, status: 'open', course_id: test_course_over.id} }
  let(:qc_alert_open_with_data) { FactoryGirl.create :qc_alert, {qc_rule_id: qc_rule2.id, status: 'open', course_id: test_course_over.id,  qc_alert_data: {"resource_id"=>"00000001-3300-4444-9999-000000000003"}} }

  let!(:get_items) do
    Acfs::Stub.resource Xikolo::Course::Item,
                        :list,
                        with: {course_id: test_course.id, content_type: 'video', published: 'true'},
        return: [{id: '00000001-3100-4444-9999-000000000004', content_id: '00000001-3100-4444-9999-000000000004'} ]
  end

  let!(:get_long_items) do
    Acfs::Stub.resource Xikolo::Course::Item,
                        :list,
                        with: {course_id: test_course2.id, content_type: 'video', published: 'true'},
        return: [{id: '00000001-3100-4444-9999-000000000005', content_id: '00000001-3100-4444-9999-000000000005'},
        {id: '00000001-3100-4444-9999-000000000006', content_id: '00000001-3100-4444-9999-000000000006'},
        {id: '00000001-3100-4444-9999-000000000007', content_id: '00000001-3100-4444-9999-000000000007'}]
  end
  let!(:get_video) do
    Acfs::Stub.resource Xikolo::Video::Video,
                        :read,
                        with: {id: '00000001-3100-4444-9999-000000000004'},
        return: {id: '00000001-3100-4444-9999-000000000004', duration: 100}

  end

  let!(:get_long_video) do
    Acfs::Stub.resource Xikolo::Video::Video,
                        :read,
                        with: {id: '00000001-3100-4444-9999-000000000005'},
        return: {id: '00000001-3100-4444-9999-000000000005', duration: 1560}
  end

  let!(:get_medium_long_video) do
    Acfs::Stub.resource Xikolo::Video::Video,
                        :read,
                        with: {id: '00000001-3100-4444-9999-000000000006'},
        return: {id: '00000001-3100-4444-9999-000000000006', duration: 2040}
  end

  let!(:get_high_long_video) do
    Acfs::Stub.resource Xikolo::Video::Video,
                        :read,
                        with: {id: '00000001-3100-4444-9999-000000000007'},
        return: {id: '00000001-3100-4444-9999-000000000007', duration: 2700}
  end
  subject { described_class.new }

  it 'should not create an alert' do
    test_course
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform test_course, qc_rule2.id
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq 0
  end

  it 'should create alerts' do
    test_course2
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform test_course2, qc_rule2.id
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq 3
  end

  it 'should close alerts when course is over' do
    test_course_over
    qc_alert_open_with_data
    qc_alert_open
    expect(qc_alert_open_with_data.status).to eq ('open')
    expect(qc_alert_open.status).to eq ('open')
    subject.perform test_course_over, qc_rule2.id
    updated_alert = QcAlert.find_by(id: qc_alert_open.id)
    updated_alert_with_data = QcAlert.find_by(id:qc_alert_open_with_data)
    expect(updated_alert.status).to eq ('closed')
    expect(updated_alert_with_data.status).to eq ('closed')
  end
end
