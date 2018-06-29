require 'spec_helper'
require 'file_collection'

class ReportStub
  def initialize(report_job)
    @report_job = report_job
  end

  def files
    FileCollection.new(@report_job.tmp_directory).tap { |files|
      FileUtils.cp(
        Rails.root.join('spec', 'support', 'files', 'course-report-example.csv'),
        files.make('course-report-example.csv')
      )
    }
  end
end

describe CreateReportJob do
  subject { described_class.new.perform(report_job.id, report_params) }

  let!(:report_job) { FactoryBot.create :report_job, :course_report }
  let(:report_params) { {} }

  let(:report_stub) { ReportStub.new(report_job) }

  context 'successful report generation' do
    before do
      allow_any_instance_of(ReportJob).to receive(:generate!).and_return(report_stub)

      Stub.service(
        :notification,
        events_url: '/events'
      )
      Stub.request(
        :notification, :post, '/events'
      ).to_return Stub.response(status: 201)
    end
    let(:s3_stubs) do
      {
        #head_object: Timeout::Error
        head_object: {
          expiration: 'Hans'
        }
      }
    end

    it 'marks the report job as finished' do
      expect { subject }.to change { report_job.reload.status }.from('pending').to('done')
    end

    it 'saves an expiry date for the file' do
      subject
      expect(report_job.reload.file_expire_date).to be_future
    end
  end

  context 'error during report upload' do
    before do
      allow_any_instance_of(ReportJob).to receive(:generate!).and_return(report_stub)

      Stub.service(
        :notification,
        events_url: '/events'
      )
      Stub.request(
        :notification, :post, '/events'
      ).to_return Stub.response(status: 201)
    end
    let(:s3_stubs) do
      {
        put_object: 'NotSuchBucket'
      }
    end

    it 'marks the report job as failed' do
      expect { subject }.to change { report_job.reload.status }.from('pending').to('failing')
    end

    it 'stores the exception trace in the database' do
      subject
      expect(report_job.reload.error_text).to include 'Report could not be stored:'
    end
  end

  context 'error during report generation' do
    before do
      allow_any_instance_of(Reports::CourseReport).to receive(:generate!).and_raise('Report failed')
    end

    it 'marks the report job as failed' do
      expect { subject }.to change { report_job.reload.status }.from('pending').to('failing')
    end

    it 'stores the exception trace in the database' do
      subject
      expect(report_job.reload.error_text).to include 'Report failed'
    end
  end
end
