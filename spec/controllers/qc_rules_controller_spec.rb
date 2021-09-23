# frozen_string_literal: true

require 'spec_helper'

describe QcRulesController, type: :controller do
  let(:qc_rule) { FactoryBot.create :qc_rule }
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

  describe '#index' do
    subject(:index) { get :index }

    it 'responds successfully' do
      expect(index).to have_http_status :ok
    end

    context 'when an active rule exists' do
      before do
        FactoryBot.create :qc_rule, is_active: true
      end

      it 'lists the active rule' do
        index
        expect(json.size).to eq 1
      end
    end
  end

  describe '#show' do
    subject(:show) { get :show, params: {id: qc_rule.id} }

    it { is_expected.to have_http_status :ok }

    it 'shows the rule' do
      show
      expect(json).to eq(QcRuleDecorator.new(qc_rule).as_json(api_version: 1).stringify_keys)
    end
  end

  describe '#update' do
    subject(:update) { patch :update, params: {id: qc_rule.id, is_active: true} }

    it 'updates the rule' do
      expect { update }.to change { qc_rule.reload.is_active }.from(false).to(true)
    end
  end
end
