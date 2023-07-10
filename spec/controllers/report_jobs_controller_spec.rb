# frozen_string_literal: true

require 'spec_helper'

describe ReportJobsController do
  let(:report_job) { create(:report_job, :course_report) }
  let(:json) { JSON.parse response.body }
  let(:params) { attributes_for(:report_job, :course_report) }
  let(:default_params) { {format: 'json'} }

  describe '#index' do
    subject(:job_index) { get :index }

    before { report_job }

    it { is_expected.to have_http_status :ok }

    it 'answers with a list' do
      job_index
      expect(json).to have(1).item
    end

    it 'answers with report job objects' do
      job_index
      expect(json[0]).to eq(ReportJobDecorator.new(report_job).as_json(api_version: 1).stringify_keys)
    end

    context 'filter by user' do
      subject(:job_user_index) { get :index, params: {user_id: '00000001-3100-4444-9999-000000000001'} }

      before do
        create(:report_job, :course_report, user_id: '00000001-3100-4444-9999-000000000001')
        create(:report_job, :course_report, user_id: '00000001-3100-4444-9999-000000000001')
        create(:report_job, :course_report, user_id: 'b2157ab3-454b-0000-bb31-976b99cb016f')
      end

      it { is_expected.to have_http_status :ok }

      it 'returns only the report jobs for the user' do
        job_user_index
        expect(json).to have(2).items
      end
    end
  end

  describe '#create' do
    subject(:create_action) { post :create, params: params }

    it { is_expected.to have_http_status :created }

    it 'creates a new report job' do
      expect { create_action }.to change(ReportJob, :count).from(0).to(1)
    end

    it 'schedules a report job for handling the report' do
      ActiveJob::Base.queue_adapter = :test
      expect { create_action }.to have_enqueued_job(CreateReportJob)
    end
  end

  describe '#update' do
    subject { patch :update, params: {id: report_job.id, report_job: params} }

    it { is_expected.to have_http_status :no_content }
  end

  describe '#show' do
    subject { get :show, params: {id: report_job.id} }

    it { is_expected.to have_http_status :ok }
  end
end
