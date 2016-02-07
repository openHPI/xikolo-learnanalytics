require 'rails_helper'

RSpec.describe Lanalytics::Metric::ExpApiCountMetric do
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:start_time) { 2.weeks.ago.to_s }
  let(:end_time) { Time.now.to_s }

  describe '#query', elasticsearch: true do
    before do
      stub_request(:get, 'http://localhost:9200/_count')
        .to_return(status: 200,
                   body: '{"count":0,"_shards":{"total":5,"successful":5,"failed":0}}',
                   headers: {'Content-Type' => 'application/json; charset=UTF-8'})
    end
    subject { described_class.query user_id, course_id, start_time, end_time, nil, nil, nil }

    it { is_expected.to eq(count: 0) }
  end
end
