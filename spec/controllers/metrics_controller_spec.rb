# frozen_string_literal: true

require 'spec_helper'

describe MetricsController, type: :controller do
  let(:default_params) { {format: 'json'} }
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:start_date) { 2.weeks.ago.to_s }
  let(:end_date) { Time.zone.now.to_s }
  let(:json) { JSON.parse response.body }

  describe '#show' do
    let(:params) do
      {
        name: 'pinboard_activity',
        user_id: user_id,
        course_id: course_id,
        start_date: start_date,
        end_date: end_date,
      }
    end

    let(:client) do
      Lanalytics::Processing::DatasourceManager.datasource('exp_events_elastic').client
    end

    let(:action) { -> { post :show, params: params } }

    context 'count' do
      it 'queries the metric, if available' do
        allow(Lanalytics::Metric::PinboardActivity)
          .to receive(:available?).and_return(true)
        expect(Lanalytics::Metric::PinboardActivity)
          .to receive(:query)
          .with(user_id: user_id, course_id: course_id, start_date: start_date, end_date: end_date)
        action.call
      end

      it 'returns error when querying an unavailable metric' do
        allow(Lanalytics::Metric::PinboardActivity)
          .to receive(:available?)
          .and_return(false)
        action.call
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json).to eq({'error' => {'name' => 'The metric is not available'}})
      end
    end
  end
end
