require 'spec_helper'

describe QcRecommendationsController do
  let(:recommendation) { FactoryBot.create :qc_recommendation }
  let(:json) { JSON.parse response.body }
  let(:params) { FactoryBot.attributes_for(:qc_recommendation) }
  let(:default_params) { {format: 'json'}}

  describe '#index' do
    it 'should answer' do
      get :index
      expect(response.status).to eq(200)
    end

  end
  describe '#show' do
    let(:action) { -> { get :show, params: {id: recommendation.id} } }
    before { action.call }

    context 'response' do
      subject { response }
      its(:status) { expect eq 200 }
    end
  end
end
