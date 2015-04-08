require 'rails_helper'

RSpec.describe Lanalytics::Metric::PinboardWatchCount do
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:start_time) { 2.weeks.ago.to_s }
  let(:end_date) { Time.now.to_s }

  describe '#query', elasticsearch: true do
    before do
      stub_request(:get, 'http://localhost:9200/_count')
        .to_return(status: 200,
                   body: '{"count":15,"_shards":{"total":5,"successful":5,"failed":0}}',
                   headers: {'Content-Type' => 'application/json; charset=UTF-8'})
    end

    let(:client) do
      Lanalytics::Processing::DatasourceManager
        .get_datasource('exp_api_elastic').client
    end

    subject { described_class.query user_id, course_id, start_time, end_date }

    it { is_expected.to eq(count: 15) }

    it 'queries the correct verbs' do
      expect(client).to receive(:count) do |options|
        expect(options[:body][:query][:filtered][:query][:bool][:must]
          .second[:match][:verb]).to eq(
            'WATCHED_QUESTION')
      end.and_return('{}')
      subject
    end
  end
end
