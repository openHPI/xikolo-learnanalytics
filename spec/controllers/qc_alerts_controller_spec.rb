require 'rspec'

describe QcAlertsController do
  let(:qc_rule) {FactoryGirl.create :qc_rule}
  let(:qc_rule2) {FactoryGirl.create :qc_rule}
  let(:alert1) { FactoryGirl.create :qc_alert, {:qc_rule_id => qc_rule.id} }
  let(:alert2) { FactoryGirl.create :qc_alert, {:course_id => '00000001-3300-4444-9999-000000000002', :qc_rule_id => qc_rule2.id} }
  let(:json) { JSON.parse response.body }
  let(:params) { FactoryGirl.attributes_for(:qc_alert) }
  let(:default_params) { {format: 'json'}}

  let(:alert_status_user){ FactoryGirl.create :qc_alert_status, {:user_id => '00000001-3100-4444-9999-000000000002', :qc_alert_id => alert1.id, :ignored => false}}
  let(:ignored_alert_status){FactoryGirl.create :qc_alert_status, {:qc_alert_id => alert1.id, :ignored => true}}
  let(:params2) {{user_id: '00000001-3100-4444-9999-000000000002'}}

  describe '#index' do
    it 'should answer' do
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe '#show' do
    let(:action) { -> { get :show, id: alert1.id } }
    before { action.call }

    context 'response' do
      subject { response }
      its(:status) { expect eq 200 }
    end

    it 'should only show alerts for user' do
      alert1
      alert2
      alert_status_user
      get :index, user_id: '00000001-3100-4444-9999-000000000002'
      expect(response.status).to eq(200)
      assert_response :success
      expect(json).to have(1).item
      expect(json[0]).to eq(QcAlertDecorator.new(alert1).as_json(api_version: 1).stringify_keys)
    end

    it 'should show only alerts that are not ignored' do
      alert1
      alert2
      ignored_alert_status
      get :index
      expect(response.status).to eq(200)
      assert_response :success
      expect(json).to have(1).item
      expect(json[0]).to eq(QcAlertDecorator.new(alert2).as_json(api_version: 1).stringify_keys)
    end
  end
  describe '#create' do

    it 'should create a new Alert' do
      qc_rule2
      qc_alerts = QcAlert.all
      expect(qc_alerts.count).to eq(0)
      post :create, qc_alert: {severity: 'high', status: 'active', qc_rule_id: qc_rule2.id}
      assert_response :success
      qc_alerts = QcAlert.all
      expect(qc_alerts.count).to eq(1)
    end

    it 'should create a new user status for an alert with a user_id' do
      qc_rule2
      qc_alerts = QcAlert.all
      expect(qc_alerts.count).to eq(0)
      post :create, qc_alert: {:severity=> 'high', :status => 'active', :qc_rule_id => qc_rule2.id}
      assert_response :success
      qc_alerts = QcAlert.all
      expect(qc_alerts.count).to eq(1)
      post :create, qc_alert_status: {qc_alert_id: alert1.id, user_id: 'b2157ab3-454b-0000-bb31-976b99cb016f' }

      get :index, params2
      expect(response.status).to eq(200)
      expect(json).to have(0).item
    end
  end

  describe 'check user and ignore filter' do
      let(:qc_rule) {FactoryGirl.create :qc_rule}
      let(:qc_rule2) {FactoryGirl.create :qc_rule}
      let!(:alert2) { FactoryGirl.create(:qc_alert, {:qc_rule_id => qc_rule.id})}
      let!(:alert3) { FactoryGirl.create(:qc_alert, {:qc_rule_id => qc_rule2.id})}
      let!(:user_id2) {'00000001-3100-4444-9999-000000000005'}
      let!(:user_id3) {'00000001-3100-4444-9999-000000000002'}
      let(:params2) {{user_id: user_id2} }

      it 'should only show alerts for specified user' do
        alert2
        alert3
        alert_status = FactoryGirl.create(:qc_alert_status, :qc_alert_id => alert2.id, :user_id => user_id2, :ignored => false)
        alert_status2 = FactoryGirl.create(:qc_alert_status, :qc_alert_id => alert2.id, :user_id => user_id3, :ignored => false)
        expect(QcAlertStatus.all.count).to eq(2)
        get :index, params2
        expect(response.status).to eq(200)
        expect(json).to have(1).item

      end

      it 'should only show not ignored alert' do
        alert2
        alert3
        alert_status2 = FactoryGirl.create(:qc_alert_status, :qc_alert_id => alert2.id, :user_id => user_id2, :ignored => false)
        alert_status3 = FactoryGirl.create(:qc_alert_status, :qc_alert_id => alert3.id, :user_id => user_id2, :ignored => true)
        expect(QcAlertStatus.all.count).to eq(2)
        get :index, params2
        expect(response.status).to eq(200)
        expect(json).to have(1).item

      end
    end
  describe '#ignore' do
    let!(:user_id2) {'00000001-3100-4444-9999-000000000005'}

    it 'should create a QcAlertStatus' do
      alert1
      alert2
      post :ignore, qc_alert_id: alert1.id, user_id: user_id2
      created_alert_status = QcAlertStatus.all.first
      expect(QcAlertStatus.all.count).to eq(1)
      expect(response.status).to eq(201)
      expect(json).to eq(QcAlertStatusDecorator.new(created_alert_status).as_json(api_version: 1).stringify_keys)

    end

    it 'should create a QcCourseStatus' do
      alert1
      alert2
      post :ignore, qc_rule_id: '00000001-3100-4444-9999-000000000002' , course_id: '00000001-3100-4444-9999-000000000003'
      created_course_status = QcCourseStatus.all.first
      expect(QcCourseStatus.all.count).to eq(1)
      expect(created_course_status.qc_rule_id).to eq('00000001-3100-4444-9999-000000000002')
      expect(created_course_status.course_id).to eq('00000001-3100-4444-9999-000000000003')
      expect(response.status).to eq(201)
      expect(json).to eq(QcCourseStatusDecorator.new(created_course_status).as_json(api_version: 1).stringify_keys)

    end

    #it 'should not create a QcAlertStatus' do
    #  alert1
    #  alert2
    #  post :ignore
   #   #expect(response.status).to eq(201)
    #  expect(json).to have(0).item
   # end


  end



  end