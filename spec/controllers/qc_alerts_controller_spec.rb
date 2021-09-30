# frozen_string_literal: true

require 'spec_helper'

describe QcAlertsController do
  let(:rule1) { FactoryBot.create :qc_rule }
  let(:rule2) { FactoryBot.create :qc_rule }

  let!(:alert1) { FactoryBot.create :qc_alert, qc_rule_id: rule1.id }
  let!(:alert2) { FactoryBot.create :qc_alert, :other_course, qc_rule_id: rule2.id }

  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

  describe '#index' do
    subject(:index) { get :index, params: params }

    let(:params) { {} }

    it { is_expected.to have_http_status :ok }

    it 'shows all alerts' do
      index
      expect(json).to have(2).items
    end

    context 'with global ignored alerts' do
      let!(:alert3) { FactoryBot.create :qc_alert, qc_rule_id: rule1.id, is_global_ignored: true }

      it 'only shows alerts that have not been globally ignored' do
        index
        expect(json).to have(2).items
        expect(json).not_to include(include('id' => alert3.id))
      end
    end

    context 'filter by course' do
      let(:params) { {course_id: alert1.course_id} }

      it 'only shows alerts for this course' do
        index
        expect(json).to have(1).item
        expect(json.first).to eq(QcAlertDecorator.new(alert1).as_json(api_version: 1).stringify_keys)
      end
    end

    describe 'filter by user' do
      let!(:alert3) { FactoryBot.create :qc_alert, qc_rule_id: rule1.id }
      let!(:alert4) { FactoryBot.create :qc_alert, qc_rule_id: rule2.id }

      let(:user_id) { '00000001-3100-4444-9999-000000000002' }

      let(:params) { {user_id: user_id} }

      context 'with a ignore status' do
        before do
          FactoryBot.create :qc_alert_status, user_id: user_id, qc_alert_id: alert3.id, ignored: true
          FactoryBot.create :qc_alert_status, user_id: user_id, qc_alert_id: alert4.id, ignored: false
        end

        it { is_expected.to have_http_status :ok }

        it 'only shows not ignored alerts for current user' do
          index
          expect(json).to have(3).item
          expect(json).not_to include(include('id' => alert3.id))
        end

        context 'with two alert statuses for another user' do
          before do
            FactoryBot.create :qc_alert_status, qc_alert_id: alert2.id, user_id: other_user_id, ignored: true
            FactoryBot.create :qc_alert_status, qc_alert_id: alert3.id, user_id: other_user_id, ignored: true
            FactoryBot.create :qc_alert_status, qc_alert_id: alert4.id, user_id: other_user_id, ignored: false
          end

          let(:other_user_id) { '00000001-3100-4444-9999-000000000003' }

          it { is_expected.to have_http_status :ok }

          it 'only shows not ignored alerts for current user' do
            index
            expect(json).to have(3).items
            expect(json).not_to include(include('id' => alert3.id))
          end
        end
      end
    end
  end

  describe '#show' do
    subject { get :show, params: {id: alert1.id} }

    it { is_expected.to have_http_status :ok }
  end

  describe '#create' do
    subject(:create) { post :create, params: {qc_alert: {severity: 'high', status: 'active', qc_rule_id: rule2.id}} }

    it { is_expected.to have_http_status :created }

    it 'creates a new alert' do
      expect { create }.to change(QcAlert, :count).from(2).to(3)
    end
  end

  describe '#ignore' do
    subject(:ignore) { post :ignore, params: params }

    let(:params) { {} }

    describe 'with alert ID' do
      let(:params) { {qc_alert_id: alert1.id, user_id: user_id2} }
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
