require 'spec_helper'
require 'sidekiq/testing'

describe InitialAnnouncementWorker do
  before do
    ActiveJob::Base.queue_adapter = :test
    Sidekiq::Testing.fake!
  end

  let!(:qc_rule2) { FactoryGirl.create :qc_rule }
  let!(:test_course) { FactoryGirl.create :test_course, {id: '00000001-3100-4444-9999-000000000002' }}
  let!(:normal_course) { FactoryGirl.create :test_course, {id: '00000001-3100-4444-9999-000000000022' }}
  let!(:course_little_enrollments) { FactoryGirl.create :test_course,
                                                        {id: '00000001-3100-4444-9999-000000000003',
      end_date: 3.days.ago }}
  let!(:test_course2) { FactoryGirl.create :test_course, {id: '00000001-3100-4444-9999-000000000015' }}
  subject { described_class.new }
  let!(:total_pages) { 101 }
  let(:headers) do
    {
        'X-Total-Pages' => '102',
        'X-Total-Count' => '10'
    }
  end
  let(:headers2) do
    {
        'X-Total-Pages' => '99',
        'X-Total-Count' => '10'
    }
  end
  let!(:get_enrollments) do
    Acfs::Stub.resource Xikolo::Course::Enrollment,
                        :list,
                        with: {course_id: test_course.id, per_page: 1},
        return: [{id: '00000001-3100-4444-9999-000000000004'}],
        headers: headers
  end

  let!(:get_enrollments3) do
    Acfs::Stub.resource Xikolo::Course::Enrollment,
                        :list,
                        with: {course_id: course_little_enrollments.id, per_page: 1},
        return: [{id: '00000001-3100-4444-9999-000000000001'}],
        headers: headers2
  end

  let!(:get_enrollments4) do
    Acfs::Stub.resource Xikolo::Course::Enrollment,
                        :list,
                        with: {course_id: test_course2.id, per_page: 1},
        return: [{id: '00000001-3100-4444-9999-000000000001'}],
        headers: headers
  end

  let!(:get_enrollments5) do
    Acfs::Stub.resource Xikolo::Course::Enrollment,
                        :list,
                        with: {course_id: normal_course.id, per_page: 1},
        return: [{id: '00000001-3100-4444-9999-000000000001'}],
        headers: headers
  end
  let!(:get_news) do
    Acfs::Stub.resource Xikolo::News::News,
                        :list,
                        with: {course_id: test_course.id, published: "true"},
        return: [{id: '00000001-3100-4444-9999-000000000002', sending_state: 1}]
  end

  let!(:get_news2) do
    Acfs::Stub.resource Xikolo::News::News,
                        :list,
                        with: {course_id: test_course2.id, published: "true"},
        return: [{id: '00000001-3100-4444-9999-000000000003'}]
  end

  let!(:get_news3) do
    Acfs::Stub.resource Xikolo::News::News,
                        :list,
                        with: {course_id: course_little_enrollments.id, published: "true"},
        return: [{id: '00000001-3100-4444-9999-000000000003', sending_state: 0}]
  end

  let!(:get_news4) do
    Acfs::Stub.resource Xikolo::News::News,
                        :list,
                        with: {course_id: normal_course.id, published: "true"},
        return: [{id: '00000001-3100-4444-9999-000000000003', sending_state: 1, publish_at: 4.days.ago}]
  end

  it 'should update open alert annotation' do
    test_course
    subject.perform test_course, qc_rule2.id
  end

  it 'should not proceed if no start_date is given' do
    test_course
    test_course.start_date = nil
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform test_course, qc_rule2.id
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq (0)
  end

  it 'should not proceed when too little enrollments' do
    course_little_enrollments
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform course_little_enrollments, qc_rule2.id
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq (0)
  end

  it 'should not proceed if course is over' do
    test_course
    test_course.end_date = 3.days.ago
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform test_course, qc_rule2.id
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq 0
  end

  it 'should create an alert ' do
    test_course2
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform test_course2, qc_rule2
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq 1
  end

  it 'should open an alert when sending state is 0' do
    test_course2
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform test_course2, qc_rule2
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq 1
  end

  it 'should not open an alert' do
    normal_course
    qc_alerts = QcAlert.all
    expect(qc_alerts.count).to eq 0
    subject.perform normal_course, qc_rule2
    qc_alerts_after = QcAlert.all
    expect(qc_alerts_after.count).to eq 0
  end
end