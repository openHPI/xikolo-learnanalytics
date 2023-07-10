# frozen_string_literal: true

require 'spec_helper'

describe QcRecommendationsController do
  let(:recommendation) { create(:qc_recommendation) }
  let(:default_params) { {format: 'json'} }

  describe '#index' do
    subject(:index) { get :index }

    it { is_expected.to have_http_status :ok }
  end

  describe '#show' do
    subject(:show) { get :show, params: {id: recommendation.id} }

    it { is_expected.to have_http_status :ok }
  end
end
