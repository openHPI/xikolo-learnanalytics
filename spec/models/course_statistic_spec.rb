require 'spec_helper'

describe CourseStatistic do
  let(:course_id) {'00000001-3300-4444-9999-000000000008'}

  before do
    Stub.service(
      :course,
      course_url: '/courses/{id}',
      stats_url: '/stats',
      course_statistic_url: '/courses/{course_id}/statistic'
    )
    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json(
      id: course_id,
      title: 'SAP Course',
      affiliated: true,
      status: 'active',
      start_date: 10.days.ago.iso8601
    )
    Stub.request(
      :course, :get, "/courses/#{course_id}/statistic"
    ).to_return Stub.json(
      enrollments: 200,
      last_day_enrollments: 20
    )
    Stub.request(
      :course, :get, '/stats',
      query: { course_id: course_id, key: 'extended' }
    ).to_return Stub.json(
      course_id: course_id,
      user_id: nil,
      student_enrollments: 25,
      student_enrollments_by_day: nil,
      student_enrollments_at_start: 0,
      student_enrollments_at_middle: 1,
      student_enrollments_at_middle_netto: 1,
      shows: 5,
      no_shows: 4,
      certificates_count: 10,
      new_users: 1
    )
    Stub.request(
      :course, :get, '/stats',
      query: { course_id: course_id, key: 'enrollments_by_day' }
    ).to_return Stub.json(
      student_enrollments_by_day: { DateTime.now.iso8601.to_s => 199}
    )

    Stub.service(
      :helpdesk,
      statistics_url: '/statistic{?course_id}'
    )
    Stub.request(
      :helpdesk, :get, '/statistic',
      query: { course_id: course_id }
    ).to_return Stub.json(
      ticket_count: 1000,
      ticket_count_last_day: 100
    )

    Stub.service(
      :pinboard,
      statistic_url: '/statistics/{id}'
    )
    Stub.request(
      :pinboard, :get, "/statistics/#{course_id}",
    ).to_return Stub.json(
      threads: 500,
      threads_last_day: 50,
      questions: 500,
      questions_last_day: 50
    )
  end

  describe '#calculate!' do
    let(:stats) { described_class.create(course_id: course_id) }
    subject { stats.calculate! }

    it 'creates a new version', versioning: true do
      expect {
        subject
      }.to change { stats.reload.versions.count }.from(1).to(2)
    end

    describe 'stats after calculation' do
      subject { super(); stats }

      its(:course_id) { should eq course_id }
      its(:course_status) { should eq 'active' }
      its(:no_shows) { should eq 4.0 }
      its(:total_enrollments) { should eq 200 }
      its(:enrollments_last_day) { should eq 20 }
      its(:enrollments_at_course_start) { should eq 0 }
      its(:enrollments_at_course_middle_netto) { should eq 1 }
      its(:threads) { should eq 500 }
      its(:threads_last_day) { should eq 50 }
      its(:questions) { should eq 500 } # @deprecated
      its(:questions_last_day) { should eq 50 } # @deprecated
      its(:enrollments_per_day) { should eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 199] }
      its(:days_since_coursestart) { should eq 10 }
    end
  end
end
