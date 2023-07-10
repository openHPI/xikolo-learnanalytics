# frozen_string_literal: true

require 'spec_helper'
require 'file_collection'

class ReportStub
  def initialize(report_job)
    @report_job = report_job
  end

  def files
    FileCollection.new(@report_job.tmp_directory).tap do |files|
      FileUtils.cp(
        Rails.root.join('spec', 'support', 'files', 'course-report-example.csv'),
        files.make('course-report-example.csv'),
      )
    end
  end
end

describe CreateReportJob do
  subject(:perform_job) { described_class.new.perform(report_job.id) }

  let(:report_job) { create(:report_job, :course_report) }
  let(:report_stub) { ReportStub.new(report_job) }

  it 'enqueued on the queue for long running reports' do
    ActiveJob::Base.queue_adapter = :test
    expect { described_class.perform_later(report_job.id) }.to have_enqueued_job.on_queue('reports_long_running')
  end

  context 'pinboard_report' do
    let(:report_job) { create(:report_job, :pinboard_report) }

    it 'enqueued on the default queue for reports' do
      ActiveJob::Base.queue_adapter = :test
      expect { described_class.perform_later(report_job.id) }.to have_enqueued_job.on_queue('reports_default')
    end
  end

  context 'successful report generation' do
    before do
      allow(ReportJob).to receive(:start).with(report_job.id).and_return report_job
      allow(report_job).to receive(:generate!).and_return(report_stub)

      Lanalytics::S3.stub_responses!(head_object: {expiration: 'Hans'})
    end

    it 'marks the report job as finished' do
      expect { perform_job }.to change { report_job.reload.status }.from('requested').to('done')
    end

    it 'saves an expiry date for the file' do
      perform_job
      expect(report_job.reload.file_expire_date).to be_future
    end
  end

  context 'error during report upload' do
    before do
      allow(ReportJob).to receive(:start).with(report_job.id).and_return report_job
      allow(report_job).to receive(:generate!).and_return(report_stub)

      Lanalytics::S3.stub_responses!(put_object: 'NotSuchBucket')
    end

    it 'marks the report job as failed' do
      expect { perform_job }.to change { report_job.reload.status }.from('requested').to('failing')
    end

    it 'stores the exception trace in the database' do
      perform_job
      expect(report_job.reload.error_text).to include 'Aws::S3::Errors'
    end
  end

  context 'error during report generation' do
    before do
      allow(ReportJob).to receive(:start).with(report_job.id).and_return report_job
      allow(report_job).to receive(:generate!).and_raise('Report failed')
    end

    it 'marks the report job as failed' do
      expect { perform_job }.to change { report_job.reload.status }.from('requested').to('failing')
    end

    it 'stores the exception trace in the database' do
      perform_job
      expect(report_job.reload.error_text).to include 'Report failed'
    end
  end
end
