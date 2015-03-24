require 'rails_helper'

RSpec.describe QueryController, type: :controller do
  describe '#show' do
    let(:body) do
      {
        query: {
          filtered: {
            query: {
              bool: {
                must: [
                  { match_phrase: { 'user.resource_uuid' => SecureRandom.uuid } },
                  { match: { verb: 'ASKED_QUESTION' } }
                ]
              }
            },
            filter: {
              range: {
                timestamp: {
                  gte: 2.weeks.ago.iso8601,
                  lte: Time.now.iso8601
                }
              }
            }
          } } }.to_json
    end
    let(:params) do
      {
        datasource: 'exp_api_elastic',
        body: body }.merge type
    end

    let(:client) do
      Lanalytics::Processing::DatasourceManager
        .get_datasource('exp_api_elastic').client
    end

    let(:action) { -> { post :show, params } }

    context 'count' do
      let(:type) { { count: true } }

      it 'queries the elasticsearch db' do
        expect(client).to receive(:count).with(hash_including(body: body)).and_return('{}')
        action.call
      end
    end

    context 'search' do
      let(:type) { { search: true } }

      it 'queries the elasticsearch db' do
        expect(client).to receive(:search).with(hash_including(body: body)).and_return('{}')
        action.call
      end
    end
  end
end
