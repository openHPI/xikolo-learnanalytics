# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QcAlertConsumer do
  subject(:consume) do
    publish.call
    Msgr::TestPool.run count: 1
  end

  before do
    Msgr.client.start
  end

  after do
    Msgr.client.stop delete: true
    Msgr::TestPool.reset
  end

  let(:course_id1) { '00000003-3300-4444-9999-000000000001' }
  let(:course_id2) { '00000003-3300-4444-9999-000000000002' }

  let(:payload1) { {id: course_id1} }
  let(:payload2) { {id: course_id2} }

  describe '#destroy_course' do
    before do
      create :qc_alert, course_id: course_id1
      create :qc_alert, course_id: course_id2
    end

    let(:msgr_route) { 'xikolo.course.course.destroy' }

    let(:publish) { -> { Msgr.publish payload1, to: msgr_route } }

    it 'deletes corresponding qc alerts' do
      expect { consume }.to change(QcAlert, :count).from(2).to(1)
    end
  end
end
