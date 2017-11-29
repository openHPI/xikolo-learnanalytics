require 'spec_helper'

describe QcRulesController, type: :controller do
  let(:qc_rule) { FactoryBot.create :qc_rule }
  let(:json) { JSON.parse response.body }
  let(:params) { FactoryBot.attributes_for(:qc_rule) }
  let(:default_params) { {format: 'json'}}

  describe '#index' do
    subject { get :index }

    it 'should answer' do
      subject
      expect(response.status).to eq(200)
    end

    context 'when an active rule exists' do
      before do
        FactoryBot.create :qc_rule, is_active: true
      end

      it 'should list that rule' do
        subject
        expect(json.size).to eq 1
      end
    end
  end

  describe '#show' do
    subject { get :show, id: qc_rule.id }

    it { is_expected.to have_http_status 200 }

    it 'should show the rule' do
      subject
      expect(json).to eq(QcRuleDecorator.new(qc_rule).as_json(api_version: 1).stringify_keys)
    end
  end

  describe '#update' do
    subject { patch :update, id: qc_rule.id, is_active: true }

    it 'should update the rule' do
      expect { subject }.to change { qc_rule.reload.is_active }.from(false).to(true)
    end
  end
end
