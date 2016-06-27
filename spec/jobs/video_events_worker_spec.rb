require 'spec_helper'
require 'sidekiq/testing'
require 'acfs/rspec'

describe VideoEventsWorker do
  before do
    ActiveJob::Base.queue_adapter = :test
    Sidekiq::Testing.fake!
    stub_request(:get, "http://localhost:5900/api").
        to_return(:status => 200, :body => lanalytics, :headers => {'Content-Type' => 'application/json;charset=utf-8'})
    stub_request(:get, "http://localhost:5900/api/query?course_id=&end_date=&metric=VideoEvents&resource_id=00000001-3100-4444-9999-000000000001&start_time=").
        to_return(:status => 200, :body => video_events, :headers => {'Content-Type' => 'application/json;charset=utf-8'})
  end
  let!(:video_events) {'
    {
       "0": {
      "time": 0,
      "total": 1,
      "play": 1,
      "seek": 1
      },
      "15": {
      "time": 345,
      "total": 5,
      "play": 5,
      "seek": 1
      },
      "30": {
      "time": 360,
      "total": 6,
      "play": 6,
      "seek": 0
      }
    }'}

  let!(:lanalytics) {'
    {
    "root_url": "http://localhost:5900/api",
    "query_url": "http://localhost:5900/api/query{?metric,user_id,course_id,start_time,end_time,resource_id}",
    "cluster_url": "http://localhost:5900/api/query/cluster",
    "recompute_cluster_group_url": "http://localhost:5900/api/cluster_groups/{id}/recompute",
    "recompute_cluster_group_teacher_action_url": "http://localhost:5900/api/cluster_groups/{cluster_group_id}/teacher_actions/{id}/recompute",
    "cluster_group_teacher_actions_url": "http://localhost:5900/api/cluster_groups/{cluster_group_id}/teacher_actions",
    "cluster_group_teacher_action_url": "http://localhost:5900/api/cluster_groups/{cluster_group_id}/teacher_actions/{id}",
    "cluster_groups_url": "http://localhost:5900/api/cluster_groups",
    "new_cluster_group_url": "http://localhost:5900/api/cluster_groups/new",
    "edit_cluster_group_url": "http://localhost:5900/api/cluster_groups/{id}/edit",
    "cluster_group_url": "http://localhost:5900/api/cluster_groups/{id}"
    }'
  }
  let(:course_id2){'00000001-3100-4444-9999-000000000001'}
  let(:qc_rule) {FactoryGirl.create :qc_rule}
  let!(:test_course) { FactoryGirl.create :test_course,
                                           {start_date: 11.days.ago,
          end_date: 5.days.from_now,
          status: 'active' }}
  let!(:get_videos) do Acfs::Stub.resource Xikolo::Course::Item,
                                           :list,
                                           with: {:content_type => 'video', :course_id =>test_course.id, :published=> 'true'},
      return: [{ id: '00000001-3100-4444-9999-000000000001', title: 'test video', content_id: '00000001-3100-4444-9999-000000000003'}]
  end
     subject { described_class.new}

  it 'should create an alert with one element in final result' do
    test_course
    alerts = QcAlert.all
    expect(alerts.count).to eq 0
    subject.perform test_course, qc_rule.id
    updated_alerts = QcAlert.all
    #expect(updated_alerts.count).to eq 1
    x = QcAlert.first
    expect(x.qc_alert_data).to eq({"resource_id"=>"00000001-3100-4444-9999-000000000001", "video_events" => "[345]"})
  end
end