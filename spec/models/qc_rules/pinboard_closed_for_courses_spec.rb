require 'spec_helper'

describe QcRules::PinboardClosedForCourses do
  subject { described_class.new qc_rule }

  let!(:qc_rule) { FactoryBot.create :qc_rule }
  let!(:test_course) { FactoryBot.build :test_course,
                                          { id: '00000001-3100-4444-9999-000000000002',
                                            start_date: 11.days.ago.iso8601,
                                            end_date: 5.days.from_now.iso8601,
                                            status: 'archive',
                                            forum_is_locked: nil}
  }

  describe '#run' do
    subject { super().run course }

    context 'when pinboard is not locked' do
      let(:course) { test_course }

      it 'should create an alert' do
        expect { subject }.to change { QcAlert.count }
                                .from(0)
                                .to(1)
      end
    end

    context 'when pinboard is locked' do
      let(:course) { test_course.merge('forum_is_locked' => true) }

      it 'should not create an alert' do
        expect { subject }.to_not change { QcAlert.count }
      end
    end
  end
end
