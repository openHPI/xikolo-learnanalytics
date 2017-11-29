require 'spec_helper'

describe QcRules::TooLongVideos do
  subject { described_class.new qc_rule2 }

  let!(:qc_rule2) { FactoryBot.create :qc_rule }
  let!(:test_course) { FactoryBot.build :test_course,
                                          {id: '00000001-3100-4444-9999-000000000002',
      start_date: 11.days.ago.iso8601,
          end_date: 5.days.from_now.iso8601,
          status: 'active' }}

  let!(:test_course_over) { FactoryBot.build :test_course,
                                          {id: '00000001-3100-4444-9999-000000000002',
      start_date: 11.days.ago.iso8601,
          end_date: 1.day.ago.iso8601,
          status: 'active' }}
  let!(:test_course2) { FactoryBot.build :test_course,
                                           {id: '00000001-3100-4444-9999-000000000003',
      start_date: 11.days.ago.iso8601,
          end_date: 5.days.from_now.iso8601,
          status: 'active' }}

  before do
    Stub.service(
      :course,
      items_url: '/items'
    )
    Stub.request(
      :course, :get, '/items',
      query: { course_id: test_course['id'], content_type: 'video', published: 'true' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000004', content_id: '00000001-3100-4444-9999-000000000004' }
    ])
    Stub.request(
      :course, :get, '/items',
      query: { course_id: test_course2['id'], content_type: 'video', published: 'true' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000005', content_id: '00000001-3100-4444-9999-000000000005' },
      { id: '00000001-3100-4444-9999-000000000006', content_id: '00000001-3100-4444-9999-000000000006' },
      { id: '00000001-3100-4444-9999-000000000007', content_id: '00000001-3100-4444-9999-000000000007' }
    ])

    Stub.service(
      :video,
      video_url: '/videos/{id}'
    )
    Stub.request(
      :video, :get, '/videos/00000001-3100-4444-9999-000000000004'
    ).to_return Stub.json(
      id: '00000001-3100-4444-9999-000000000004',
      duration: 100
    )
    Stub.request(
      :video, :get, '/videos/00000001-3100-4444-9999-000000000005'
    ).to_return Stub.json(
      id: '00000001-3100-4444-9999-000000000005',
      duration: 1560
    )
    Stub.request(
      :video, :get, '/videos/00000001-3100-4444-9999-000000000006'
    ).to_return Stub.json(
      id: '00000001-3100-4444-9999-000000000006',
      duration: 2040
    )
    Stub.request(
      :video, :get, '/videos/00000001-3100-4444-9999-000000000007'
    ).to_return Stub.json(
      id: '00000001-3100-4444-9999-000000000007',
      duration: 2700
    )
  end

  describe '#run' do
    subject { super().run course }
    let(:course) { test_course }

    it 'should not create an alert' do
      expect { subject }.to_not change { QcAlert.count }
    end

    context 'when there are three long videos' do
      let(:course) { test_course2 }

      it 'should create three alert' do
        expect { subject }.to change { QcAlert.count }
                                .from(0)
                                .to(3)
      end
    end

    context 'when the course is over' do
      let(:course) { test_course_over }

      let(:alert1) { FactoryBot.create :qc_alert, {qc_rule_id: qc_rule2.id, status: 'open', course_id: test_course_over['id']} }
      let(:alert2) { FactoryBot.create :qc_alert, {qc_rule_id: qc_rule2.id, status: 'open', course_id: test_course_over['id'], qc_alert_data: {'resource_id' => '00000001-3300-4444-9999-000000000003'}} }

      it 'should close both alerts' do
        expect { subject }.to change { [alert1.reload.status, alert2.reload.status] }
                                .from(%w(open open))
                                .to(%w(closed closed))
      end
    end
  end
end
