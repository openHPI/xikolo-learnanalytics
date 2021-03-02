require 'spec_helper'

describe CalculateCourseStatsWorker do
  subject { described_class.new.perform }

  let(:active_course1)     { '00000001-3300-4444-9999-000000000001' }
  let(:active_course2)     { '00000001-3300-4444-9999-000000000002' }
  let(:preparation_course) { '00000001-3300-4444-9999-000000000003' }
  let(:external_course)    { '00000001-3300-4444-9999-000000000004' }

  before do
    Stub.request(:course, :get)
      .to_return Stub.json(courses_url: '/courses')
    Stub.request(
      :course, :get, '/courses',
      query: { groups: 'any' }
    ).to_return Stub.json([
      { id: active_course1, status: 'active', external_course_url: nil },
      { id: preparation_course, status: 'preparation', external_course_url: nil },
      { id: external_course, status: 'active', external_course_url: 'http://mooc.house/courses/ex' },
      { id: active_course2, status: 'active', external_course_url: nil },
    ])
  end

  before do
    # Stub out the calculation of statistics, it is tested in the model spec
    allow_any_instance_of(CourseStatistic).to receive(:calculate!)
  end

  it 'creates a new statistic object for each public, internal course' do
    expect(CourseStatistic.count).to eq 0
    subject
    expect(CourseStatistic.pluck(:course_id)).to match_array [active_course1, active_course2]
  end

  it 'sends an event for other services to consume' do
    expect(Msgr).to receive(:publish).with(anything, to: 'xikolo.lanalytics.course_stats.calculate')
    subject
  end
end
