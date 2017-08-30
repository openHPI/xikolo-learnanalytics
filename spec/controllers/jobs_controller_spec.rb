require 'spec_helper'

describe JobsController do
  let(:job) { FactoryGirl.create :course_report_job }
  let(:json) { JSON.parse response.body }
  let(:params) { FactoryGirl.attributes_for(:course_report_job) }
  let(:default_params) { {format: 'json'}}

  describe '#index' do
    before { job }
    subject { get :index }

    it { is_expected.to have_http_status :ok }

    it 'answers with a list' do
      subject
      expect(json).to have(1).item
    end

    it 'answers with job objects' do
      subject
      expect(json[0]).to eq(JobDecorator.new(job).as_json(api_version: 1).stringify_keys)
    end

    context 'filter by user' do
      let!(:job1) { FactoryGirl.create(:course_report_job, user_id: '00000001-3100-4444-9999-000000000001')}
      let!(:job2) { FactoryGirl.create(:course_report_job, user_id: '00000001-3100-4444-9999-000000000001')}
      let!(:job3) { FactoryGirl.create(:course_report_job, user_id: 'b2157ab3-454b-0000-bb31-976b99cb016f')}

      subject { get :index, user_id: '00000001-3100-4444-9999-000000000001' }

      it { is_expected.to have_http_status :ok }

      it 'returns only the jobs for the user' do
        subject
        expect(json).to have(2).items
      end
    end
  end

  describe '#create' do
    subject { post :create, params }

    it { is_expected.to have_http_status :created }

    it 'creates a new job' do
      expect { subject }.to change { Job.count }.from(0).to(1)
    end

    it 'marks the job as requested' do
      subject
      expect(Job.last.status).to eq 'requested'
    end

    it 'schedules a job for handling the report' do
      ActiveJob::Base.queue_adapter = :test
      expect {
        subject
      }.to have_enqueued_job(CreateReportJob)
    end
  end

  describe '#update' do
    subject { patch :update, id: job.id, job: params }

    it { is_expected.to have_http_status :no_content }
  end

  describe '#show' do
    subject { get :show, id: job.id }

    it { is_expected.to have_http_status :ok }
  end
end
