# frozen_string_literal: true

require 'spec_helper'

describe CourseStatistic do
  let(:course_id) { '00000001-3300-4444-9999-000000000008' }

  before do
    Stub.request(:course, :get)
      .to_return Stub.json({
        course_url: '/courses/{id}',
        stats_url: '/stats',
        course_statistic_url: '/courses/{course_id}/statistic',
      })
    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json({
      id: course_id,
      title: 'SAP Course',
      groups: ['affiliated'],
      status: 'active',
      start_date: 10.days.ago.iso8601,
    })
    Stub.request(
      :course, :get, "/courses/#{course_id}/statistic"
    ).to_return Stub.json({
      enrollments: 200,
      last_day_enrollments: 20,
    })
    Stub.request(
      :course, :get, '/stats',
      query: {course_id: course_id, key: 'extended'}
    ).to_return Stub.json({
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
      new_users: 1,
    })
    Stub.request(
      :course, :get, '/stats',
      query: {course_id: course_id, key: 'enrollments_by_day'}
    ).to_return Stub.json({
      student_enrollments_by_day: {DateTime.now.iso8601.to_s => 199},
    })

    Stub.request(
      :xikolo, :get,
      headers: {'Authorization' => /Bearer .+/}
    ).to_return Stub.json({
      course_open_badge_stats_url: '/bridges/lanalytics/courses/{course_id}/open_badge_stats',
      course_ticket_stats_url: '/bridges/lanalytics/courses/{course_id}/ticket_stats',
    })
    Stub.request(
      :xikolo, :get, "/courses/#{course_id}/open_badge_stats",
      headers: {'Authorization' => /Bearer .+/}
    ).to_return Stub.json({
      badges_issued: 185,
    })
    Stub.request(
      :xikolo, :get, "/courses/#{course_id}/ticket_stats",
      headers: {'Authorization' => /Bearer .+/}
    ).to_return Stub.json({
      ticket_count: 1000,
      ticket_count_last_day: 100,
    })

    Stub.request(:pinboard, :get)
      .to_return Stub.json({statistic_url: '/statistics/{id}'})
    Stub.request(
      :pinboard, :get, "/statistics/#{course_id}"
    ).to_return Stub.json({
      threads: 500,
      threads_last_day: 50,
      questions: 500,
      questions_last_day: 50,
    })

    # elasticsearch
    stub_request(:post, 'http://localhost:9200/_count')
      .to_return(status: 200, body: +'')
    stub_request(:post, 'http://localhost:9200/_search')
      .to_return(
        status: 200,
        headers: {'Content-Type' => 'application/json'},
        body: {aggregations: {distinct_user_count: {value: 42}}}.to_json,
      )
  end

  describe '#calculate!' do
    subject(:calculate) { stats.calculate! }

    let(:stats) { described_class.create(course_id: course_id) }

    it 'creates a new version', versioning: true do
      expect { calculate }.to change { stats.reload.versions.count }.from(1).to(2)
    end

    describe 'stats after calculation' do
      subject { super(); stats }

      its(:course_id) { is_expected.to eq course_id }
      its(:course_status) { is_expected.to eq 'active' }
      its(:no_shows) { is_expected.to eq 4.0 }
      its(:total_enrollments) { is_expected.to eq 200 }
      its(:enrollments_last_day) { is_expected.to eq 20 }
      its(:enrollments_at_course_start) { is_expected.to eq 0 }
      its(:enrollments_at_course_middle_netto) { is_expected.to eq 1 }
      its(:threads) { is_expected.to eq 500 }
      its(:threads_last_day) { is_expected.to eq 50 }
      its(:questions) { is_expected.to eq 500 } # @deprecated
      its(:questions_last_day) { is_expected.to eq 50 } # @deprecated
      its(:enrollments_per_day) { is_expected.to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 199] }
      its(:days_since_coursestart) { is_expected.to eq 10 }
      its(:helpdesk_tickets) { is_expected.to eq 1_000 }
      its(:helpdesk_tickets_last_day) { is_expected.to eq 100 }
      its(:badge_issues) { is_expected.to eq 185 }
    end
  end
end
