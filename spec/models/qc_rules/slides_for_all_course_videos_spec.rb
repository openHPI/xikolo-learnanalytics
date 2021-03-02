require 'spec_helper'

describe QcRules::SlidesForAllCourseVideos do
  subject { described_class.new qc_rule }

  let!(:qc_rule) { FactoryBot.create :qc_rule }
  let!(:test_course) { FactoryBot.build :test_course,
                                          { id: '00000001-3100-4444-9999-000000000002',
      start_date: DateTime.now.iso8601,
      end_date: 5.days.from_now.iso8601,
      status: 'preparation',
      forum_is_locked: nil
  }}
  let!(:test_course2) { FactoryBot.build :test_course,
                                          { id: '00000001-3100-4444-9999-000000000003',
      start_date: DateTime.now.iso8601,
      end_date: 5.days.from_now.iso8601,
      status: 'preparation',
      forum_is_locked: nil
  }}

  before do
    Stub.request(:course, :get)
      .to_return Stub.json(items_url: '/items')
    Stub.request(
      :course, :get, '/items',
      query: { course_id: test_course['id'], content_type: 'video' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000004', content_id: '00000001-3100-4444-9999-000000000004' }
    ])
    Stub.request(
      :course, :get, '/items',
      query: { course_id: test_course2['id'], content_type: 'video' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000003', content_id: '00000001-3100-4444-9999-000000000003' }
    ])

    Stub.request(:video, :get)
      .to_return Stub.json(video_url: '/videos/{id}')
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

  describe '#run' do
    subject { super().run course }

    context 'when slides are not present' do
      let(:course) { test_course }

      it 'should create an alert' do
        expect { subject }.to change { QcAlert.count }
                                .from(0)
                                .to(1)
      end
    end

    context 'when slides are present' do
      let(:course) { test_course2 }

      it 'should not create an alert' do
        expect { subject }.to_not change { QcAlert.count }
      end
    end
  end
end
