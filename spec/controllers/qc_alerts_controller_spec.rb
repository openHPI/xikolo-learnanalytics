# frozen_string_literal: true

require 'spec_helper'

describe QcAlertsController do
  let(:rule) { create(:qc_rule) }
  let(:another_rule) { create(:qc_rule) }
  let!(:alert_one) { create(:qc_alert, qc_rule_id: rule.id) }
  let!(:alert_two) { create(:qc_alert, :other_course, qc_rule_id: another_rule.id) }

  let(:json) { response.parsed_body }
  let(:default_params) { {format: 'json'} }

  describe '#index' do
    subject(:list_alerts) { get :index, params: params }

    let(:params) { {} }

    it { is_expected.to have_http_status :ok }

    it 'shows all alerts' do
      list_alerts
      expect(json).to have(2).items
    end

    context 'with global ignored alerts' do
      let!(:alert_ignored) { create(:qc_alert, qc_rule_id: rule.id, is_global_ignored: true) }

      it 'only shows alerts that have not been globally ignored' do
        list_alerts
        expect(json).to have(2).items
        expect(json).not_to include(include('id' => alert_ignored.id))
      end
    end

    context 'filter by course' do
      let(:params) { {course_id: alert_one.course_id} }

      it 'only shows alerts for this course' do
        list_alerts
        expect(json).to have(1).item
        expect(json.first).to eq(QcAlertDecorator.new(alert_one).as_json(api_version: 1).stringify_keys)
      end
    end

    describe 'filter by user' do
      let!(:alert_ignored) { create(:qc_alert, qc_rule_id: rule.id) }
      let!(:alert_other) { create(:qc_alert, qc_rule_id: another_rule.id) }

      let(:user_id) { '00000001-3100-4444-9999-000000000002' }

      let(:params) { {user_id: user_id} }

      context 'with a ignore status' do
        before do
          create(:qc_alert_status, user_id: user_id, qc_alert_id: alert_ignored.id, ignored: true)
          create(:qc_alert_status, user_id: user_id, qc_alert_id: alert_other.id, ignored: false)
        end

        it { is_expected.to have_http_status :ok }

        it 'only shows not ignored alerts for current user' do
          list_alerts
          expect(json).to have(3).item
          expect(json).not_to include(include('id' => alert_ignored.id))
        end

        context 'with two alert statuses for another user' do
          before do
            create(:qc_alert_status, qc_alert_id: alert_two.id, user_id: other_user_id, ignored: true)
            create(:qc_alert_status, qc_alert_id: alert_ignored.id, user_id: other_user_id, ignored: true)
            create(:qc_alert_status, qc_alert_id: alert_other.id, user_id: other_user_id, ignored: false)
          end

          let(:other_user_id) { '00000001-3100-4444-9999-000000000003' }

          it { is_expected.to have_http_status :ok }

          it 'only shows not ignored alerts for current user' do
            list_alerts
            expect(json).to have(3).items
            expect(json).not_to include(include('id' => alert_ignored.id))
          end
        end
      end
    end
  end

  describe '#show' do
    subject { get :show, params: {id: alert_one.id} }

    it { is_expected.to have_http_status :ok }
  end

  describe '#create' do
    subject(:create_alert) { post :create, params: {qc_alert: {severity: 'high', status: 'active', qc_rule_id: another_rule.id}} }

    it { is_expected.to have_http_status :created }

    it 'creates a new alert' do
      expect { create_alert }.to change(QcAlert, :count).from(2).to(3)
    end
  end

  describe '#ignore' do
    subject(:ignore) { post :ignore, params: params }

    let(:params) { {} }

    describe 'with alert ID' do
      let(:params) { {qc_alert_id: alert_one.id, user_id: user_id2} }
      let(:user_id2) { '00000001-3100-4444-9999-000000000005' }

      it { is_expected.to have_http_status :created }

      it 'creates a QcAlertStatus' do
        expect { ignore }.to change(QcAlertStatus, :count).from(0).to(1)
      end

      it 'returns new alert status' do
        ignore
        expect(json).to eq(QcAlertStatusDecorator.new(QcAlertStatus.last).as_json(api_version: 1).stringify_keys)
      end
    end

    describe 'with rule ID' do
      let(:params) { {qc_rule_id: rule_id, course_id: course_id} }
      let(:rule_id) { '00000001-3100-4444-9999-000000000002' }
      let(:course_id) { '00000001-3100-4444-9999-000000000003' }

      it { is_expected.to have_http_status :created }

      it 'creates a QcCourseStatus' do
        expect { ignore }.to change(QcCourseStatus, :count).from(0).to(1)
      end

      it 'creates the correct QcCourseStatus' do
        ignore
        created_course_status = QcCourseStatus.last
        expect(created_course_status.qc_rule_id).to eq(rule_id)
        expect(created_course_status.course_id).to eq(course_id)
      end

      it 'returns new course status' do
        ignore
        expect(json).to eq(QcCourseStatusDecorator.new(QcCourseStatus.last).as_json(api_version: 1).stringify_keys)
      end
    end
  end
end
