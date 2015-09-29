require 'rails_helper'

RSpec.describe Api::QueryController, type: :controller do
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:start_date) { 2.weeks.ago.to_s }
  let(:end_date) { Time.now.to_s }

  describe '#show' do
    let(:params) do
      {
        metric: 'PinboardActivity',
        user_id: user_id,
        course_id: course_id,
        start_time: start_date,
        end_time: end_date
      }
    end

    let(:client) do
      Lanalytics::Processing::DatasourceManager.datasource('exp_api_elastic').client
    end

    let(:action) { -> { post :show, params } }

    context 'count' do
      it 'queries the metric' do
        expect(Lanalytics::Metric::PinboardActivity)
          .to receive(:query)
          .with(user_id, course_id, start_date, end_date)
        action.call
      end
    end
  end
end
