# frozen_string_literal: true

require 'spec_helper'

describe QcRules::SlidesForAllCourseVideos do
  subject(:rule) { described_class.new qc_rule }

  let!(:qc_rule) { create(:qc_rule) }
  let!(:test_course) do
    build(:test_course,
      id: '00000001-3100-4444-9999-000000000002',
      start_date: DateTime.now.iso8601,
      end_date: 5.days.from_now.iso8601,
      status: 'preparation',
      forum_is_locked: nil)
  end
  let!(:test_course2) do
    build(:test_course,
      id: '00000001-3100-4444-9999-000000000003',
      start_date: DateTime.now.iso8601,
      end_date: 5.days.from_now.iso8601,
      status: 'preparation',
      forum_is_locked: nil)
  end

  before do
    Stub.request(:course, :get)
      .to_return Stub.json({items_url: '/items'})
    Stub.request(
      :course, :get, '/items',
      query: {course_id: test_course['id'], content_type: 'video'}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000004', content_id: '00000001-3100-4444-9999-000000000004'},
    ])
    Stub.request(
      :course, :get, '/items',
      query: {course_id: test_course2['id'], content_type: 'video'}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000003', content_id: '00000001-3100-4444-9999-000000000003'},
    ])

    Stub.request(:video, :get)
      .to_return Stub.json({video_url: '/videos/{id}'})
    Stub.request(
      :video, :get, '/videos/00000001-3100-4444-9999-000000000004'
    ).to_return Stub.json({
      id: '00000001-3100-4444-9999-000000000004',
      thumbnail_archive_id: nil,
    })
    Stub.request(
      :video, :get, '/videos/00000001-3100-4444-9999-000000000003'
    ).to_return Stub.json({
      id: '00000001-3100-4444-9999-000000000003',
      thumbnail_archive_id: 'abc',
    })
  end

  describe '#run' do
    subject(:run) { rule.run course }

    context 'when slides are not present' do
      let(:course) { test_course }

      it 'creates an alert' do
        expect { run }.to change(QcAlert, :count).from(0).to(1)
      end
    end

    context 'when slides are present' do
      let(:course) { test_course2 }

      it 'does not create an alert' do
        expect { run }.not_to change(QcAlert, :count)
      end
    end
  end
end
