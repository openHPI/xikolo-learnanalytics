require 'spec_helper'
require 'sidekiq/testing'

describe AnnouncementFailedWorker do
  before  do
    ActiveJob::Base.queue_adapter = :test
    stub_restify(
      :news,
      :news,
      :get,
      with: {published: 'true'},
      body_res: [published_news]
    )
    stub_request(:get, "http://localhost:3200/").
        to_return(:status => 200, :body => notification, :headers => {'Content-Type' => 'application/json;charset=utf-8'})
    stub_request(:get, "http://notification.xikolo.tld/").
        to_return(:status => 200, :body => notification, :headers => {'Content-Type' => 'application/json;charset=utf-8'})
    stub_request(:get, "http://localhost:3200/mail_log_stats?news_id=c97b9403-0e81-4857-a52f-a02e901856b1").
        to_return(:status => 200, :body => mail_logs, :headers => {'Content-Type' => 'application/json;charset=utf-8'})
  end
  let!(:notification) {'{
    "mail_log_stats_url": "http://localhost:3200/mail_log_stats{?news_id}",
    "events_url": "http://localhost:3200/events"
    }'}
  let!(:published_news){
    [{
      id: 'c97b9403-0e81-4857-a52f-a02e901856b1',
      title: 'Hallo',
      content_rtid: '948a29f9-07f5-43bb-b62c-f7c4497d00cc',
      author_id: '00000001-3100-4444-9999-000000000002',
      publish_at: 2.days.ago.iso8601,
      published_until: 2.days.from_now.iso8601,
      receivers: 500
    }]
  }
  let!(:mail_logs) {'{
    "news_id": "c97b9403-0e81-4857-a52f-a02e901856b1",
    "count": 205,
    "success_count": 200,
    "error_count": 0,
    "disabled_count": 0,
    "unique_count": 205,
    "oldest": "'+3.days.ago.iso8601+'",
    "newest": "'+1.day.ago.iso8601+'"
    }'}

  let!(:qc_rule) {FactoryGirl.create :qc_rule}
  subject { described_class.new}

  it 'creates an alert when delta exists' do
    alerts = QcAlert.all
    expect(alerts.count).to eq 0
    subject.perform(nil, qc_rule.id)
    updated_alerts = QcAlert.all
    expect(updated_alerts.count).to eq 1
    expect(updated_alerts.first.qc_alert_data).to eq({"resource_id"=>"c97b9403-0e81-4857-a52f-a02e901856b1"})
  end
end