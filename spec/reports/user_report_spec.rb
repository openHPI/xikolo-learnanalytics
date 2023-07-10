# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Reports::UserReport do
  let(:report_job) { create(:report_job, task_scope: '00000001-3300-4444-9999-000000000001') }

  let(:user_report) { described_class.new(report_job) }

  let(:base_requests) do
    Stub.request(:course, :get)
      .to_return Stub.json(
        course_url: 'http://course.xikolo.tld/courses/{id}',
        sections_url: 'http://course.xikolo.tld/sections',
        enrollments_url: 'http://course.xikolo.tld/enrollments',
        items_url: 'http://course.xikolo.tld/items',
      )

    Stub.request(
      :course, :get, "/courses/#{report_job.task_scope}"
    ).to_return Stub.json(
      id: report_job.task_scope,
      course_code: 'report_course',
    )

    Stub.request(:account, :get)
      .to_return Stub.json(
        accounts_url: 'http://account.xikolo.tld',
        users_url: 'http://account.xikolo.tld/users',
      )

    Stub.request(
      :account, :get, '/users',
      query:
      {
        confirmed: true,
        per_page: 250,
      }
    ).to_return Stub.json([])
  end

  around do |example|
    report_job.with_tmp_directory(&example)
  end

  before do
    base_requests
  end

  context 'a csv file is generated successfully' do
    before do
      user_report.generate!
    end

    it 'generates one csv file' do
      expect(user_report.files.count).to eq 1
      expect(user_report.files.names.first).to end_with '.csv'
    end

    it 'the CSV file has correct headers' do
      file = File.open("#{Rails.root}/tmp/#{report_job.id}/#{user_report.files.names.first}")
      headers = CSV.read(file, headers: true).headers

      expect(headers).to contain_exactly('User Pseudo ID', 'Age Group', 'Language', 'Created')
    end
  end
end
