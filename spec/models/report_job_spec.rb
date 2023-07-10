# frozen_string_literal: true

require 'spec_helper'

describe ReportJob do
  let(:params) do
    {
      task_type: 'course_report',
      user_id: 'b2157ab3-454b-0000-bb31-976b99cb016f',
      task_scope: 'internet2021',
    }
  end

  describe '::create' do
    subject(:created_report_job) { described_class.create(params) }

    it 'sets initial status to `requested`' do
      expect(created_report_job.status).to eq('requested')
    end

    it 'sets correct task type`' do
      expect(created_report_job.task_type).to eq('course_report')
    end
  end

  describe '::create_and_enqueue' do
    subject(:enqueued_report_job) do
      described_class.create_and_enqueue(params)
    end

    it 'schedules a report job' do
      ActiveJob::Base.queue_adapter = :test
      expect { enqueued_report_job }.to have_enqueued_job(CreateReportJob).with do |job_id|
        expect(described_class.find(job_id).status).to eq('queued')
      end
    end
  end

  describe '::queue_name' do
    subject(:queue_name) { described_class.queue_name(report_job.id) }

    let(:report_job) { create(:report_job, report_type) }

    %i[
      course_report
      combined_course_report
      course_events_report
      user_report
      openwho_course_report
      openwho_combined_course_report
    ].each do |long_running_report|
      context long_running_report.to_s do
        let(:report_type) { long_running_report }

        it 'returns the queue for long running reports' do
          expect(queue_name).to eq(:reports_long_running)
        end
      end
    end

    %i[
      unconfirmed_user_report
      submission_report
      pinboard_report
      enrollment_statistics_report
      course_content_report
      overall_course_summary_report
    ].each do |default_report|
      context default_report.to_s do
        let(:report_type) { default_report }

        it 'returns the default queue for reports' do
          expect(queue_name).to eq(:reports_default)
        end
      end
    end
  end
end
