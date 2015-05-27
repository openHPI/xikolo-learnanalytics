require 'rails_helper'

RSpec.describe Lanalytics::Metric::QuestionResponseTime do
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:start_time) { 2.weeks.ago.to_s }
  let(:end_time) { Time.now.to_s }
  let(:question_id) { SecureRandom.uuid }

  describe '#query' do
    before do
      stub_request(:get, 'http://localhost:9200/_search')
        .to_return(
          [
            {
              status: 200,
              body: {
                'hits' =>                   {
                  'hits' =>                       [
                    {
                      '_index' => 'lanalytics', '_type' => 'EXP_STATEMENT', '_id' => 'AU1rhfRl36o_qzg4AgtU',
                      '_source' =>                             {
                        'user' => {'resource_uuid' => '00000001-3100-4444-9999-000000000002'},
                        'verb' => 'ANSWERED_QUESTION',
                        'resource' => {
                          'resource_uuid' => 'c999933a-0ef0-47cf-b106-dd45b67ce77b'
                        },
                        'timestamp' => Time.zone.now.iso8601,
                        'in_context' => {'question_id' => question_id}
                      }
                    }
                  ]
                }}.to_json,
              headers: {'Content-Type' => 'application/json; charset=UTF-8'}
            }
          ],
          [
            {
              status: 200,
              body: {'hits' => {'hits' => [{'_index' => 'lanalytics', '_type' => 'EXP_STATEMENT', '_id' => 'AU1rhf0g36o_qzg4AgxK', '_score' => 1.2368064, '_source' => {'user' => {'resource_uuid' => '00000001-3100-4444-9999-000000000001'}, 'verb' => 'ASKED_QUESTION', 'resource' => {'resource_uuid' => "#{question_id}"}, 'timestamp' => 10.minutes.ago.iso8601}}]}}.to_json,
              headers: {'Content-Type' => 'application/json; charset=UTF-8'}
            }
          ]
        )
    end

    let(:client) do
      Lanalytics::Processing::DatasourceManager
        .get_datasource('exp_api_elastic').client
    end

    subject { described_class.query user_id, course_id, start_time, end_time }

    it { is_expected.to eq(average: 600) }

    it 'queries the correct verbs' do
      expect(client).to receive(:search) do |options|
        expect(options[:body][:query][:filtered][:query][:bool][:must]
          .second[:match][:verb]).to eq(
            'ANSWERED_QUESTION')
      end.and_call_original
      expect(client).to receive(:search) do |options|
        expect(options[:body][:query][:filtered][:query][:bool][:must]
          .second[:match][:verb]).to eq(
            'ASKED_QUESTION')
      end.and_call_original
      subject
    end
  end
end
