require 'rails_helper'

RSpec.describe Lanalytics::Metric::VideoVisitCount do
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:start_time) { 2.weeks.ago.to_s }
  let(:end_time) { Time.now.to_s }

  describe '#query', elasticsearch: true do
    before do
      stub_request(:post, 'http://localhost:9200/_count')
        .to_return(status: 200,
                   body: '{"count":15,"_shards":{"total":5,"successful":5,"failed":0}}',
                   headers: {'Content-Type' => 'application/json; charset=UTF-8'})
    end

    let(:client) do
      Lanalytics::Processing::DatasourceManager.datasource('exp_events_elastic').client
    end

    subject { described_class.query user_id: user_id, course_id: course_id, start_date: start_time, end_date: end_time }

    it { is_expected.to eq(count: 15) }
  end

end
