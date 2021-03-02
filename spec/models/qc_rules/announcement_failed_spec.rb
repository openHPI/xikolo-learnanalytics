require 'spec_helper'

describe QcRules::AnnouncementFailed do
  before do
    Stub.request(:news, :get)
      .to_return Stub.json(news_index_url: '/news')
    Stub.request(
      :news, :get, '/news',
      query: { published: 'true' }
    ).to_return Stub.json([
      {
        id: 'c97b9403-0e81-4857-a52f-a02e901856b1',
        title: 'Hallo',
        author_id: '00000001-3100-4444-9999-000000000002',
        publish_at: 2.days.ago.iso8601,
        published_until: 2.days.from_now.iso8601,
        receivers: 500
      }
    ])

    Stub.request(:notification, :get)
      .to_return Stub.json(mail_log_stats_url: '/mail_log_stats{?news_id}')
    Stub.request(
      :notification, :get, '/mail_log_stats?news_id=c97b9403-0e81-4857-a52f-a02e901856b1'
    ).to_return Stub.json(
      news_id: 'c97b9403-0e81-4857-a52f-a02e901856b1',
      count: 205,
      success_count: 200,
      error_count: 0,
      disabled_count: 0,
      unique_count: 205,
      oldest: 3.days.ago.iso8601,
      newest: 1.day.ago.iso8601
    )
  end

  let!(:qc_rule) { FactoryBot.create :qc_rule }
  subject { described_class.new(qc_rule) }

  describe '#run' do
    subject { super().run }

    context 'when delta exists' do
      it 'creates a new alert' do
        expect { subject }.to change { QcAlert.count }
                                .from(0)
                                .to(1)
      end

      it 'stores the announcement ID with the alert' do
        subject
        expect(QcAlert.first.qc_alert_data).to eq(
          'resource_id' => 'c97b9403-0e81-4857-a52f-a02e901856b1'
        )
      end
    end
  end
end
