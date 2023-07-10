# frozen_string_literal: true

require 'spec_helper'

describe QcRules::PinboardClosedForCourses do
  subject(:rule) { described_class.new qc_rule }

  let!(:qc_rule) do
    create(:qc_rule,
      is_active: true,
      worker: 'PinboardClosedForCoursesWorker')
  end
  let!(:preparation_course) do
    build(:test_course,
      id: '00000001-3100-4444-9999-000000000003',
      start_date: 30.days.from_now.iso8601,
      end_date: 60.days.from_now.iso8601,
      status: 'preparation',
      forum_is_locked: nil)
  end
  let!(:active_course) do
    build(:test_course,
      id: '00000001-3100-4444-9999-000000000002',
      start_date: 30.days.from_now.iso8601,
      end_date: 60.days.from_now.iso8601,
      status: 'active',
      forum_is_locked: nil)
  end
  let!(:archive_course) do
    build(:test_course,
      id: '00000001-3100-4444-9999-000000000004',
      start_date: 30.days.ago.iso8601,
      end_date: 10.days.ago.iso8601,
      status: 'archive',
      forum_is_locked: nil)
  end

  describe '#run' do
    subject(:run) { rule.run course }

    context 'for course in preparation' do
      context 'when pinboard is not locked' do
        let(:course) { preparation_course }

        it 'does not create an alert' do
          expect { run }.not_to change(QcAlert, :count)
        end
      end

      context 'when pinboard is locked' do
        let(:course) { preparation_course.merge('forum_is_locked' => true) }

        it 'does not create an alert' do
          expect { run }.not_to change(QcAlert, :count)
        end
      end
    end

    context 'for active course' do
      context 'when pinboard is not locked' do
        let(:course) { active_course }

        it 'does not create an alert' do
          expect { run }.not_to change(QcAlert, :count)
        end
      end

      context 'when pinboard is locked' do
        let(:course) { active_course.merge('forum_is_locked' => true) }

        it 'does not create an alert' do
          expect { run }.not_to change(QcAlert, :count)
        end
      end
    end

    context 'for archived course' do
      context 'when pinboard is not locked' do
        let(:course) { archive_course }

        it 'creates an alert' do
          expect { run }.to change(QcAlert, :count).from(0).to(1)
        end
      end

      context 'when pinboard is locked' do
        let(:course) { archive_course.merge('forum_is_locked' => true) }

        it 'does not create an alert' do
          expect { run }.not_to change(QcAlert, :count)
        end

        context 'with existing alert' do
          let!(:alert) do
            create(:qc_alert, qc_rule_id: qc_rule.id, course_id: course['id'])
          end

          it 'closes an existing alert' do
            expect { run }.to change { alert.reload.status }.from('open').to('closed')
          end
        end
      end
    end
  end
end
