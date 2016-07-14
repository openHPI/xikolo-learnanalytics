require 'spec_helper'
require 'sidekiq/testing'

describe LowCourseCommunicationWorker do
  before  do
    ActiveJob::Base.queue_adapter = :test
    Sidekiq::Testing.fake!
  end

  let!(:qc_rule2) {FactoryGirl.create :qc_rule}
  let!(:test_course) {FactoryGirl.create :test_course,
                                         {id: '00000001-3100-4444-9999-000000000002',
                                          start_date: 11.days.ago,
                                          end_date: 5.days.from_now,
                                          status: 'active'}}
  let!(:test_course2) {FactoryGirl.create :test_course,
                                         {id: '00000001-3100-4444-9999-000000000003',
                                          start_date: 11.days.ago,
                                          end_date: 5.days.from_now,
                                          status: 'active'}}
  let(:headers) do
    {
      'X-Total-Pages' => '102',
      'X-Total-Count' => '10'
    }
  end
  let!(:get_enrollments) do  Acfs::Stub.resource Xikolo::Course::Enrollment,
                                                 :list,
                                                 with: {course_id: test_course.id, per_page: 1},
      return: [{ id: '00000001-3100-4444-9999-000000000004'}],
      headers: headers
  end
  let!(:get_enrollments2) do  Acfs::Stub.resource Xikolo::Course::Enrollment,
                                                 :list,
                                                 with: {course_id: test_course2.id, per_page: 1},
      return: [{ id: '00000001-3100-4444-9999-000000000004'}],
      headers: headers
  end
  let!(:get_news) do
    stub_restify(
      :news,
      :news,
      :get,
      with: {course_id: test_course.id, published: "true", per_page: 1, page: 1},
      body_res: [[{ id: '00000001-3100-4444-9999-000000000002', publish_at: 11.days.ago}]]
    )
  end
  let!(:get_news2) do
    stub_restify(
      :news,
      :news,
      :get,
      with: {course_id: test_course2.id, published: "true", per_page: 1, page: 1},
      body_res: [[{ id: '00000001-3100-4444-9999-000000000002', publish_at: 9.days.ago}]]
    )
  end
  subject { described_class.new}

  it 'should create an alert when announcement is too old' do
    test_course
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform test_course, qc_rule2.id
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq 1
  end

  it 'should close alert if announcement is not too old' do
    test_course2
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform test_course2, qc_rule2.id
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq 0
  end
end