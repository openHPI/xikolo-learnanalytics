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
    let(:new_file_id) { SecureRandom.uuid }
    before do
      allow_any_instance_of(ReportJob).to receive(:generate!).and_return(report_stub)

      Stub.service(
        :file,
        uploaded_files_url: 'http://localhost:4000/uploaded_files'
      )

      Stub.service(
        :notification,
        events_url: '/events'
      )
      Stub.request(
        :notification, :post, '/events'
      ).to_return Stub.response(status: 201)
    end

    let!(:create_file_stub) {
      Stub.request(
        :file, :post, '/uploaded_files'
      ).to_return Stub.json(
        id: new_file_id,
        path: 'reports'
      )
    }

    it 'marks the report job as finished' do
      expect { subject }.to change { report_job.reload.status }.from('pending').to('done')
    end

    it 'registers the ZIP file with the file service' do
      subject
      expect(create_file_stub).to have_been_requested
    end

    it 'stores the ZIP file at the right location in the share' do
      subject
      expect(File.exist? 'spec/support/data_dir/reports/course-report-example.zip').to be true
    end

    it 'saves an expiry date for the file' do
      subject
      expect(report_job.reload.file_expire_date.future?).to be true
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
