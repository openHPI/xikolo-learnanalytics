# frozen_string_literal: true

require 'spec_helper'

describe CalculateCourseStatsWorker do
  subject(:perform) { described_class.new.perform }

  let(:active_course1)     { '00000001-3300-4444-9999-000000000001' } # rubocop:disable RSpec/IndexedLet
  let(:active_course2)     { '00000001-3300-4444-9999-000000000002' } # rubocop:disable RSpec/IndexedLet
  let(:preparation_course) { '00000001-3300-4444-9999-000000000003' }
  let(:external_course)    { '00000001-3300-4444-9999-000000000004' }

  before do
    Stub.request(:course, :get)
      .to_return Stub.json({courses_url: '/courses'})
    Stub.request(
      :course, :get, '/courses',
      query: {groups: 'any'}
    ).to_return Stub.json([
      {id: active_course1, status: 'active', external_course_url: nil},
      {id: preparation_course, status: 'preparation', external_course_url: nil},
      {id: external_course, status: 'active', external_course_url: 'http://mooc.house/courses/ex'},
      {id: active_course2, status: 'active', external_course_url: nil},
    ])

    # Stub out the calculation of statistics, it is tested in the model spec
    [active_course1, active_course2].each do |active_course_id|
      allow(CourseStatistic).to receive(:find_or_create_by).with(course_id: active_course_id)
        .and_wrap_original {|method, *args|
          method.call(*args).tap {|instance| allow(instance).to receive(:calculate!) }
        }
    end
  end

  it 'creates a new statistic object for each public, internal course' do
    expect(CourseStatistic.count).to eq 0
    perform
    expect(CourseStatistic.pluck(:course_id)).to contain_exactly(active_course1, active_course2)
  end

  it 'sends an event for other services to consume' do
    expect(Msgr).to receive(:publish).with(anything, to: 'xikolo.lanalytics.course_stats.calculate')
    perform
  end
end
