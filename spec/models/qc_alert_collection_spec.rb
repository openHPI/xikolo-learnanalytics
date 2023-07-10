# frozen_string_literal: true

require 'spec_helper'

describe QcAlertCollection do
  let!(:rule) { create(:qc_rule) }
  let(:course_id) { SecureRandom.uuid }

  let(:alert_params) { {status: 'open', qc_rule_id: rule.id, course_id: course_id} }
  let(:parameterized_alert_params) { alert_params.merge(qc_alert_data: {'foo' => 'bar'}) }
  let(:closed_alert_params) { {status: 'closed', qc_rule_id: rule.id, course_id: course_id} }
  let(:closed_parameterized_alert_params) { closed_alert_params.merge(qc_alert_data: {'foo' => 'bar'}) }

  let(:collection) { rule.alerts_for(course_id: course_id) }

  describe '#open!' do
    subject(:open) { collection.open!(**attrs) }

    let(:attrs) { {severity: 'high', annotation: 'annotation'} }

    context 'with an existing closed alert' do
      let!(:alert) { create(:qc_alert, closed_alert_params) }

      it 'reopens the alert' do
        expect { open }.to change { alert.reload.status }
          .from('closed')
          .to('open')
      end

      it 'stores the passed attributes' do
        expect { open }.to change { [alert.reload.severity, alert.reload.annotation] }
          .from(['low', ''])
          .to(%w[high annotation])
      end
    end

    context 'with an existing closed alert that is parameterized' do
      let!(:alert) { create(:qc_alert, closed_parameterized_alert_params) }

      before { collection.with_data(foo: 'bar') }

      it 'reopens the alert' do
        expect { open }.to change { alert.reload.status }
          .from('closed')
          .to('open')
      end

      it 'stores the passed attributes' do
        expect { open }.to change { [alert.reload.severity, alert.reload.annotation] }
          .from(['low', ''])
          .to(%w[high annotation])
      end

      it 'retains all custom parameters' do
        expect { open }.not_to change(alert, :qc_alert_data)
      end

      context 'when passing additional parameters' do
        let(:attrs) { super().merge(qc_alert_data: {'baz' => 'bam'}) }

        it 'combines all custom parameters' do
          open
          QcAlert.last.tap do |alert|
            expect(alert.qc_alert_data).to eq('foo' => 'bar', 'baz' => 'bam')
          end
        end
      end
    end

    context 'without existing alerts' do
      it 'creates a new alert' do
        expect { open }.to change(QcAlert, :count).from(0).to(1)
      end

      it 'stores the passed attributes' do
        open
        QcAlert.last.tap do |alert|
          expect(alert.severity).to eq 'high'
          expect(alert.annotation).to eq 'annotation'
        end
      end
    end
  end

  describe '#close!' do
    subject(:close) { collection.close! }

    context 'with an existing open alert for the course' do
      let!(:alert) { create(:qc_alert, alert_params) }

      it 'closes the alert' do
        expect { close }.to change { alert.reload.status }.to('closed')
      end
    end

    context 'with an existing open alert for the course that is parameterized' do
      let!(:alert) { create(:qc_alert, parameterized_alert_params) }

      before { collection.with_data(foo: 'bar') }

      it 'closes the alert' do
        expect { close }.to change { alert.reload.status }.to('closed')
      end

      it 'retains all custom parameters' do
        expect { close }.not_to change(alert, :qc_alert_data)
      end
    end

    context 'without existing alerts' do
      it 'does not create a new alert just to close it' do
        expect { close }.not_to change(QcAlert, :count)
      end
    end
  end
end
