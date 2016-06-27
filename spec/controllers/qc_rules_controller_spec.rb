require 'rspec'

describe QcRulesController do
  let(:qc_rule) { FactoryGirl.create :qc_rule }
  let(:json) { JSON.parse response.body }
  let(:params) { FactoryGirl.attributes_for(:qc_rule) }
  let(:default_params) { {format: 'json'}}


  describe '#index' do
    it 'should answer' do
      get :index
      expect(response.status).to eq(200)
    end

    it 'should create a new Rule' do

      expect(QcRule.all.count).to eq(0)
      post :create, qc_rule: {worker:'PinboardActivityWorker', is_active: true}
      assert_response :success
      rules = QcRule.all
      expect(rules.count).to eq(1)
    end
  end

  describe '#show' do
    it 'should show a rule' do
      qc_rule
      get :show, id: qc_rule.id
      expect(response.status).to eq(200)
      expect(json).to eq(QcRuleDecorator.new(qc_rule).as_json(api_version: 1).stringify_keys)
    end

  end

  describe "#update" do
    it 'should show update rule' do
      qc_rule
      expect(qc_rule.is_active).to eq(false)
      patch :update, id: qc_rule.id, is_active: true
      qc_rule.reload
      expect(qc_rule.is_active).to eq(true)
    end
  end

end