require 'spec_helper'

describe CourseStatisticsController do
  let(:default_params) { {format: 'json'}}
  let(:json) { JSON.parse response.body }
  let(:course_id) {'00000001-3300-4444-9999-000000000006'}

  describe '#index' do
    subject { get :index, params }
    let(:params) { {} }

    it { is_expected.to have_http_status :ok }

    it 'responds with an empty list' do
      subject
      expect(json).to be_empty
    end

    context 'when fetching historic data for a course', versioning: true do
      before { FactoryGirl.create :course_statistic, :calculated }
      let(:params) { super().merge(historic_data: 'true', course_id: course_id, start_date: 2.days.ago.to_s) }

      it { is_expected.to have_http_status :ok }

      it 'should retrieve historic data' do
        subject
        expect(json).to have(1).item
        expect(json[0]['course_id']).to eq course_id
      end

      context 'with incorrect parameters' do
        let(:params) { super().except(:course_id) }

        it { is_expected.to have_http_status :ok }

        it 'should retrieve empty array if historic data parameters are wrong' do
          subject
          expect(json).to be_empty
        end
      end
    end
  end

  describe '#show' do
    subject { get :show, id: course_id }
    before { FactoryGirl.create :course_statistic, :calculated }

    it { is_expected.to have_http_status :ok }
  end
end
