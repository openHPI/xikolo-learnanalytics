# frozen_string_literal: true

require 'spec_helper'

describe ReportJob, type: :model do
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
end
