# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QcAlertConsumer do
  before do
    Msgr.client.start
  end

  after do
    Msgr.client.stop delete: true
    Msgr::TestPool.reset
  end

  let(:course_id_1) { '00000003-3300-4444-9999-000000000001' }
  let(:course_id_2) { '00000003-3300-4444-9999-000000000002' }

  let(:payload_1) do
    {
      id: course_id_1,
      deleted: true
    }
  end
  let(:payload_2) do
    {
      id: course_id_2,
      deleted: false
    }
  end

  subject do
    publish.call
    Msgr::TestPool.run count: 2
  end

  describe '#update_course' do
    before do
      FactoryBot.create :qc_alert, course_id: course_id_1
      FactoryBot.create :qc_alert, course_id: course_id_2
    end

    let(:msgr_route) { 'xikolo.course.course.update' }

    context 'for course update w/ delete' do
      let(:publish) { -> { Msgr.publish payload_1, to: msgr_route } }

      it 'deletes corresponding qc alerts' do
        expect { subject }.to change(QcAlert, :count).from(2).to(1)
      end
    end

    context 'for course update w/o delete' do
      let(:publish) { -> { Msgr.publish payload_2, to: msgr_route } }

      it 'retains all qc alerts' do
        expect { subject }.to_not change(QcAlert, :count)
      end
    end
  end
end
