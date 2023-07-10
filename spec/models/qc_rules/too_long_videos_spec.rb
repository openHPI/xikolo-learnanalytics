# frozen_string_literal: true

require 'spec_helper'

describe QcRules::TooLongVideos do
  subject(:rule) { described_class.new qc_rule }

  let!(:qc_rule) { create(:qc_rule) }
  let!(:test_course) do
    build(:test_course,
      id: '00000001-3100-4444-9999-000000000002',
      start_date: 11.days.ago.iso8601,
      end_date: 5.days.from_now.iso8601,
      status: 'active')
  end

  let!(:test_course_over) do
    build(:test_course,
      id: '00000001-3100-4444-9999-000000000002',
      start_date: 11.days.ago.iso8601,
      end_date: 1.day.ago.iso8601,
      status: 'active')
  end
  let!(:test_course2) do
    build(:test_course,
      id: '00000001-3100-4444-9999-000000000003',
      start_date: 11.days.ago.iso8601,
      end_date: 5.days.from_now.iso8601,
      status: 'active')
  end

  before do
    Stub.request(:course, :get)
      .to_return Stub.json(items_url: '/items')
    Stub.request(
      :course, :get, '/items',
      query: {course_id: test_course['id'], content_type: 'video', published: 'true'}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000004', content_id: '00000001-3100-4444-9999-000000000004'},
    ])
    Stub.request(
      :course, :get, '/items',
      query: {course_id: test_course2['id'], content_type: 'video', published: 'true'}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000004', content_id: '00000001-3100-4444-9999-000000000004'},
      {id: '00000001-3100-4444-9999-000000000005', content_id: '00000001-3100-4444-9999-000000000005'},
      {id: '00000001-3100-4444-9999-000000000006', content_id: '00000001-3100-4444-9999-000000000006'},
      {id: '00000001-3100-4444-9999-000000000007', content_id: '00000001-3100-4444-9999-000000000007'},
    ])

    Stub.request(:video, :get)
      .to_return Stub.json(video_url: '/videos/{id}')
    Stub.request(
      :video, :get, '/videos/00000001-3100-4444-9999-000000000004'
    ).to_return Stub.json(
      id: '00000001-3100-4444-9999-000000000004',
      duration: 700, # 11 min 40 sec
    )
    Stub.request(
      :video, :get, '/videos/00000001-3100-4444-9999-000000000005'
    ).to_return Stub.json(
      id: '00000001-3100-4444-9999-000000000005',
      duration: 1560, # 26 min
    )
    Stub.request(
      :video, :get, '/videos/00000001-3100-4444-9999-000000000006'
    ).to_return Stub.json(
      id: '00000001-3100-4444-9999-000000000006',
      duration: 2040, # 34 min
    )
    Stub.request(
      :video, :get, '/videos/00000001-3100-4444-9999-000000000007'
    ).to_return Stub.json(
      id: '00000001-3100-4444-9999-000000000007',
      duration: 2700, # 45 min
    )
  end

  describe '#run' do
    subject(:run) { rule.run course }

    let(:course) { test_course }

    it 'does not create an alert' do
      expect { run }.not_to change(QcAlert, :count)
    end

    context 'when there are three long videos' do
      let(:course) { test_course2 }

      it 'creates three alerts' do
        expect { run }.to change(QcAlert, :count)
          .from(0)
          .to(3)
      end

      context 'when the thresholds are more strict' do
        before do
          yaml_config <<~YML
            qc_alert:
              video_duration:
                low: 10
                medium: 20
                high: 30
          YML
        end

        it 'creates four alerts' do
          expect { run }.to change(QcAlert, :count)
            .from(0)
            .to(4)
        end
      end
    end

    context 'when the course is over' do
      let(:course) { test_course_over }

      let(:alert) do
        create(:qc_alert,
          qc_rule_id: qc_rule.id,
          status: 'open',
          course_id: test_course_over['id'])
      end
      let(:alert_with_data) do
        create(:qc_alert,
          qc_rule_id: qc_rule.id,
          status: 'open',
          course_id: test_course_over['id'],
          qc_alert_data: {'resource_id' => '00000001-3300-4444-9999-000000000003'})
      end

      it 'closes both alerts' do
        expect { run }.to change { [alert.reload.status, alert_with_data.reload.status] }
          .from(%w[open open])
          .to(%w[closed closed])
      end
    end
  end
end
