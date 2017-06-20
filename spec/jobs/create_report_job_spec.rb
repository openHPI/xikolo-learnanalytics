require 'spec_helper'

class ReportStub
  def initialize(job)
    @job = job
  end

  def files
    FileUtils.cp(
      Rails.root.join('spec', 'support', 'files', 'course-report-example.csv'),
      @job.tmp_directory.join('course-report-example.csv')
    )

    [@job.tmp_directory.join('course-report-example.csv')]
  end
end

describe CreateReportJob do
  subject { described_class.new.perform(job.id, report_params) }

  let!(:job) { FactoryGirl.create :course_export_job }
  let(:report_params) { {} }

  let(:report_stub) { ReportStub.new(job) }

  context 'successful report generation' do
    let(:new_file_id) { SecureRandom.uuid }
    before do
      allow_any_instance_of(Job).to receive(:generate!).and_return(report_stub)
    end

    let!(:create_file_stub) {
      Stub.request(
        :file, :post, '/uploaded_files'
      ).to_return Stub.json(
        id: new_file_id,
        path: 'reports'
      )
    }

    let!(:upload_file_stub) {
      Stub.request(
        :file, :post, "/uploaded_files/#{new_file_id}/upload"
      ).to_return Stub.response
    }

    it 'marks the job as finished' do
      expect { subject }.to change { job.reload.status }.from('pending').to('done')
    end

    it 'registers the ZIP file with the file service' do
      subject
      expect(create_file_stub).to have_been_requested
    end

    it 'uploads the ZIP file to the file service' do
      subject
      expect(upload_file_stub).to have_been_requested
    end

    it 'saves an expiry date for the file' do
      subject
      expect(job.reload.file_expire_date.future?).to be true
    end
  end

  context 'error during report generation' do
    before do
      allow_any_instance_of(Reports::CourseReport).to receive(:generate!).and_raise('Report failed')
    end

    it 'marks the job as failed' do
      expect { subject }.to change { job.reload.status }.from('pending').to('failing')
    end
  end
end
