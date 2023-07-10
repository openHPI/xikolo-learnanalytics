# frozen_string_literal: true

require 'spec_helper'

describe 'ReportJob: Delete', type: :request do
  subject(:delete) { api.rel(:report_job).delete(id: report_job.id).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:report_job) { create(:report_job) }

  it 'responds with 204 No Content' do
    expect(delete.response.status).to eq :no_content
  end

  context 'for running report job' do
    let(:report_job) { create(:report_job, status: 'started') }

    it 'responds with 409 Conflict' do
      expect { delete }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :conflict
      end
    end
  end
end
