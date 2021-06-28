# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lanalytics::Metric::QuestionResponseTime do
  let(:user_id) { '12771d9d-f8ef-4a69-915c-8812bb21becf' }
  let(:course_id) { '30c212b9-1be5-4443-adf4-25696645255d' }
  let(:start_time) { '2021-06-10 10:20:18 UTC' }
  let(:end_time) { '2021-06-24 12:20:20 UTC' }
  let(:question_id) { 'b0a9164c-092b-4b70-bbae-1e59046fc171' }

  describe '#query' do
    subject(:query) { described_class.query user_id: user_id, course_id: course_id, start_date: start_time, end_date: end_time }

    before do
      stub_request(:post, 'http://localhost:9200/_search')
        .to_return(
          [
            {
              status: 200,
              body: {
                'hits' => {
                  'hits' => [
                    {
                      '_index' => 'lanalytics', '_type' => 'EXP_STATEMENT', '_id' => 'AU1rhfRl36o_qzg4AgtU',
                      '_source' => {
                        'user' => {'resource_uuid' => '00000001-3100-4444-9999-000000000002'},
                        'verb' => 'ANSWERED_QUESTION',
                        'resource' => {
                          'resource_uuid' => 'c999933a-0ef0-47cf-b106-dd45b67ce77b',
                        },
                        'timestamp' => '2021-06-24T10:26:45Z',
                        'in_context' => {'question_id' => question_id},
                      }
                    },
                  ],
                },
              }.to_json,
              headers: {'Content-Type' => 'application/json; charset=UTF-8'},
            },
          ],
          [
            {
              status: 200,
              body: {
                'hits' => {
                  'hits' => [
                    {
                      '_index' => 'lanalytics', '_type' => 'EXP_STATEMENT', '_id' => 'AU1rhf0g36o_qzg4AgxK', '_score' => 1.2368064,
                      '_source' => {
                        'user' => {'resource_uuid' => '00000001-3100-4444-9999-000000000001'},
                        'verb' => 'ASKED_QUESTION',
                        'resource' => {'resource_uuid' => question_id},
                        'timestamp' => '2021-06-24T10:24:00Z',
                      }
                    },
                  ],
                },
              }.to_json,
              headers: {'Content-Type' => 'application/json; charset=UTF-8'},
            },
          ],
        )
    end

    it { is_expected.to eq(average: 165) }

    it 'queries the correct verbs' do
      client = Lanalytics::Processing::DatasourceManager.datasource('exp_events_elastic').client
      original = client.method(:search)

      expect(client).to receive(:search) do |options|
        expect(
          options.dig(:body, :query, :bool, :must, 0, :match, :verb),
        ).to eq('ANSWERED_QUESTION')
        original.call(options)
      end

      expect(client).to receive(:search) do |options|
        expect(
          options.dig(:body, :query, :bool, :must, 1, :match, :verb),
        ).to eq('ASKED_QUESTION')
        original.call(options)
      end

      query
    end
  end
end
