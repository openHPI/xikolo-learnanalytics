# frozen_string_literal: true

require 'spec_helper'

describe CourseStatisticsController do
  let(:default_params) { {format: 'json'} }
  let(:json) { response.parsed_body }
  let(:course_id) { '00000001-3300-4444-9999-000000000006' }

  describe '#index' do
    subject(:index) { get :index, params: }

    let(:params) { {} }

    it { is_expected.to have_http_status :ok }

    it 'responds with an empty list' do
      index
      expect(json).to be_empty
    end

    context 'when fetching historic data for a course', :versioning do
      before { create(:course_statistic, :calculated) }

      let(:params) { super().merge(historic_data: 'true', course_id:, start_date: 2.days.ago.to_s) }

      it { is_expected.to have_http_status :ok }

      it 'retrieves historic data' do
        index
        expect(json).to have(1).item
        expect(json[0]['course_id']).to eq course_id
      end

      context 'with incorrect parameters' do
        let(:params) { super().except(:course_id) }

        it { is_expected.to have_http_status :ok }

        it 'retrieves empty array if historic data parameters are wrong' do
          index
          expect(json).to be_empty
        end
      end
    end
  end

  describe '#show' do
    subject { get :show, params: {id: course_id} }

    before { create(:course_statistic, :calculated) }

    it { is_expected.to have_http_status :ok }
  end
end
