require 'spec_helper'

describe JobsController do
  let(:job) { FactoryGirl.create :job }
  let(:json) { JSON.parse response.body }
  let(:params) { FactoryGirl.attributes_for(:job) }
  let(:default_params) { {format: 'json'}}

  describe '#index' do

    it 'should answer' do
      get :index
      expect(response.status).to eq(200)
    end

    it 'should answer with a list' do
      job
      get :index
      expect(response.status).to eq(200)
      expect(json).to have(1).item
    end

    it 'should answer with job objects' do
      job
      get :index
      expect(response.status).to eq(200)
      assert_response :success
      expect(json[0]).to eq(JobDecorator.new(job).as_json(api_version: 1).stringify_keys)
    end

    it 'should create a new job' do
      jobs = Job.all
      expect(jobs.count).to eq(0)
      post :create, job: {file_id: 'b2147ab3-424b-4777-bb31-976b99cb016f', status: 'pending'}
      assert_response :success
      jobs = Job.all
      expect(jobs.count).to eq(1)
    end

    it 'should update a job' do
      patch :update, id: job.id, job: params
      expect(response.status).to be 204
    end

    describe 'check user filter' do
      let!(:job1) { FactoryGirl.create(:job, user_id: '00000001-3100-4444-9999-000000000001')}
      let!(:job2) { FactoryGirl.create(:job, user_id: '00000001-3100-4444-9999-000000000001')}
      let!(:job3) { FactoryGirl.create(:job, user_id: 'b2157ab3-454b-0000-bb31-976b99cb016f')}
      let(:params2) {{user_id: '00000001-3100-4444-9999-000000000001' }}
      let(:action) { -> { get :index, params2}}
      before { action.call }
      it 'should only returns jobs for user' do
        jobs = Job.all
        expect(jobs.count).to eq(3)
        expect(response.status).to eq(200)
        expect(json).to have(2).item
      end
    end
  end

  describe '#show' do
    let(:action) { -> { get :show, id: job.id } }
    before { action.call }

    context 'response' do
      subject { response }
      its(:status) { expect eq 200 }

    end
  end
end
