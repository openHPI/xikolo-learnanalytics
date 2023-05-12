# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lanalytics::Metric::Certificates do
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:start_date) { 2.weeks.ago.to_s }
  let(:body) do
    {
      'aggregations' => {
        'confirmation_of_participation' => {
          'doc_count' => 0,
          'course' => {
            'doc_count_error_upper_bound' => 0,
            'sum_other_doc_count' => 0,
            'buckets' => [],
          },
          'total' => {
            'value' => 5.0,
          },
        },
        'certificate' => {
          'doc_count' => 0,
          'course' => {
            'doc_count_error_upper_bound' => 0,
            'sum_other_doc_count' => 0,
            'buckets' => [],
          },
          'total' => {
            'value' => 4.0,
          },
        },
        'record_of_achievement' => {
          'doc_count' => 0,
          'course' => {
            'doc_count_error_upper_bound' => 0,
            'sum_other_doc_count' => 0,
            'buckets' => [],
          },
          'total' => {
            'value' => 1.0,
          },
        },
      },
    }
  end

  describe '#query' do
    subject(:query) do
      described_class.query course_id: course_id, start_date: start_date
    end

    before do
      stub_request(:post, 'http://localhost:9200/_search')
        .to_return(
          status: 200,
          body: body.to_json,
          headers: {'Content-Type' => 'application/json; charset=UTF-8'},
        )
    end

    it 'returns correct numbers for the different types of achievements' do
      expect(query['confirmation_of_participation']).to eq 5
      expect(query['qualified_certificate']).to eq 4
      expect(query['record_of_achievement']).to eq 1
    end
  end
end
