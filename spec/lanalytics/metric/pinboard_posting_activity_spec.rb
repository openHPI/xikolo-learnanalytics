require 'rails_helper'

RSpec.describe Lanalytics::Metric::PinboardPostingActivity do
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:start_time) { 2.weeks.ago.to_s }
  let(:end_time) { Time.now.to_s }

  describe '#query', elasticsearch: true do
    before do
      stub_request(:get, 'http://localhost:9200/_count')
        .to_return(status: 200,
                   body: '{"count":15,"_shards":{"total":5,"successful":5,"failed":0}}',
                   headers: {'Content-Type' => 'application/json; charset=UTF-8'})
    end

    let(:client) do
      Lanalytics::Processing::DatasourceManager.datasource('exp_api_elastic').client
    end

    subject { described_class.query user_id, course_id, start_time, end_time, nil, nil, nil }

    it { is_expected.to eq(count: 15) }

    it 'queries the course_id' do
      expect(client).to receive(:count) do |options|
        expect(options[:body][:query][:bool][:must]
          .second[:bool][:should].first[:match]['in_context.course_id']).to eq(
            course_id)
      end.and_return('{}')
      subject
    end

    it 'queries the user_id' do
      expect(client).to receive(:count) do |options|
        expect(options[:body][:query][:bool][:must]
          .third[:match]['user.resource_uuid']).to eq(
            user_id)
      end.and_return('{}')
      subject
    end

    it 'queries the time' do
      expect(client).to receive(:count) do |options|
        expect(options[:body][:query][:bool][:filter][:range][:timestamp]
          ).to eq ({
            gte: DateTime.parse(start_time).iso8601,
            lte: DateTime.parse(end_time).iso8601})
      end.and_return('{}')
      subject
    end
  end
end
