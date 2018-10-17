require 'spec_helper'

describe QcAlertsController do
  let(:rule) { FactoryBot.create :qc_rule }
  let(:rule2) { FactoryBot.create :qc_rule }
  let!(:alert1) { FactoryBot.create :qc_alert, qc_rule_id: rule.id }
  let!(:alert2) { FactoryBot.create :qc_alert, :other_course, qc_rule_id: rule2.id }
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

  describe '#index' do
    subject { get :index, params: params }
    let(:params) { {} }

    it { is_expected.to have_http_status 200 }

    context 'with ignored alerts' do
      # Ignore alert1
      before { FactoryBot.create :qc_alert_status, qc_alert_id: alert1.id, ignored: true }

      it { is_expected.to have_http_status 200 }

      it 'should only show alerts that have not been ignored' do
        subject
        expect(json).to have(1).item
        expect(json.first).to eq(QcAlertDecorator.new(alert2).as_json(api_version: 1).stringify_keys)
      end
    end

    describe 'filter by user' do
      let(:params) { { user_id: filter_user_id } }
      let(:filter_user_id) { '00000001-3100-4444-9999-000000000002' }

      context 'with a notification for one user' do
        # Notify the user about alert1
        before { FactoryBot.create :qc_alert_status, user_id: filter_user_id, qc_alert_id: alert1.id, ignored: false }

        it { is_expected.to have_http_status 200 }

        it 'should only show alerts for that user' do
          subject
          expect(json).to have(1).item
          expect(json.first).to eq(QcAlertDecorator.new(alert1).as_json(api_version: 1).stringify_keys)
        end
      end

      context 'with two more alerts and another user' do
        let!(:alert3) { FactoryBot.create(:qc_alert, {qc_rule_id: rule.id}) }
        let!(:alert4) { FactoryBot.create(:qc_alert, {qc_rule_id: rule2.id}) }
        let(:other_user_id) { '00000001-3100-4444-9999-000000000003' }

        context 'with two alert statuses for different users' do
          before do
            FactoryBot.create(:qc_alert_status, qc_alert_id: alert3.id, user_id: filter_user_id, ignored: false)
            FactoryBot.create(:qc_alert_status, qc_alert_id: alert3.id, user_id: other_user_id, ignored: false)
          end

          it { is_expected.to have_http_status 200 }

          it 'should only show alerts for specified user' do
            subject
            expect(json).to have(1).item
          end
        end

        context 'with two alert statuses' do
          before do
            FactoryBot.create(:qc_alert_status, qc_alert_id: alert3.id, user_id: filter_user_id, ignored: false)
            FactoryBot.create(:qc_alert_status, qc_alert_id: alert4.id, user_id: filter_user_id, ignored: true)
          end

          it { is_expected.to have_http_status 200 }

          it 'should only show not-ignored alerts' do
            subject
            expect(json).to have(1).item
          end
        end
      end
    end
  end

  describe '#show' do
    subject { get :show, params: {id: alert1.id} }

    it { is_expected.to have_http_status 200 }
  end

  describe '#create' do
    subject { post :create, params: {qc_alert: { severity: 'high', status: 'active', qc_rule_id: rule2.id }} }

    it { is_expected.to have_http_status 201 }

    it 'should create a new alert' do
      expect { subject }.to change { QcAlert.count }.from(2).to(3)
    end
  end

  describe '#ignore' do
    subject { post :ignore, params: params }
    let(:params) { {} }

    describe 'with alert ID' do
      let(:params) { { qc_alert_id: alert1.id, user_id: user_id2 } }
      let(:user_id2) { '00000001-3100-4444-9999-000000000005' }

      it { is_expected.to have_http_status 201 }

      it 'should create a QcAlertStatus' do
        expect { subject }.to change { QcAlertStatus.count }.from(0).to(1)
      end

      it 'should return new alert status' do
        subject
        expect(json).to eq(QcAlertStatusDecorator.new(QcAlertStatus.last).as_json(api_version: 1).stringify_keys)
      end
    end

    describe 'with rule ID' do
      let(:params) { { qc_rule_id: rule_id, course_id: course_id } }
      let(:rule_id) { '00000001-3100-4444-9999-000000000002' }
      let(:course_id) { '00000001-3100-4444-9999-000000000003' }

      it { is_expected.to have_http_status 201 }

      it 'should create a QcCourseStatus' do
        expect { subject }.to change { QcCourseStatus.count }.from(0).to(1)
      end

      it 'should create the correct QcCourseStatus' do
        subject
        created_course_status = QcCourseStatus.last
        expect(created_course_status.qc_rule_id).to eq(rule_id)
        expect(created_course_status.course_id).to eq(course_id)
      end

      it 'should return new course status' do
        subject
        expect(json).to eq(QcCourseStatusDecorator.new(QcCourseStatus.last).as_json(api_version: 1).stringify_keys)
      end
    end
  end
end
