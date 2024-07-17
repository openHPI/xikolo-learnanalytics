# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lanalytics::Metric::CoursePoints do
  let(:user_id) { '12771d9d-f8ef-4a69-915c-8812bb21becf' }
  let(:course_id) { '30c212b9-1be5-4443-adf4-25696645255d' }
  let(:start_time) { '2021-06-10 10:20:18 UTC' }
  let(:end_time) { '2021-06-24 12:20:20 UTC' }
  let(:body) do
    {
      'hits' => {
        'hits' => [
          {
            '_index' => 'lanalytics', '_type' => 'EXP_STATEMENT', '_id' => 'AU1rhfRl36o_qzg4AgtU',
            '_source' => {
              'user' => {'resource_uuid' => user_id},
              'verb' => 'COMPLETED_COURSE',
              'resource' => {
                'resource_uuid' => course_id,
              },
              'timestamp' => '2021-06-24T10:26:24Z',
              'in_context' => {
                'course_id' => course_id,
                'points_achieved' => 999,
              },
            }
          },
        ],
      },
    }
  end

  describe '#query' do
    subject(:query) { described_class.query user_id:, course_id:, start_date: start_time, end_date: end_time }

    before do
      stub_request(:post, 'http://localhost:9200/_search')
        .to_return(
          status: 200,
          body: body.to_json,
          headers: {'Content-Type' => 'application/json; charset=UTF-8'},
        )
    end

    it { is_expected.to eq(points: 999) }

    it 'queries the correct verbs' do
      client = Lanalytics::Processing::DatasourceManager.datasource('exp_events_elastic').client

      expect(client).to receive(:search) do |options|
        expect(options.dig(:body, :query, :filtered, :query, :bool, :must)
          .second[:match][:verb]).to eq('COMPLETED_COURSE')
      end.and_return(body)

      query
    end
  end
end
