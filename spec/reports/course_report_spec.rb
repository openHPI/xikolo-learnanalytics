# frozen_string_literal:true

require 'spec_helper'
require 'csv'

describe Reports::CourseReport do
  let!(:report_job) { create(:report_job, :course_report) }

  let(:course_report) { described_class.new(report_job) }

  let(:base_requests) do
    Stub.request(:course, :get)
      .to_return Stub.json({
        course_url: '/courses/{id}',
        sections_url: '/sections',
        enrollments_url: '/enrollments',
        items_url: '/items',
      })

    Stub.request(:course, :get, "/courses/#{report_job.task_scope}")
      .to_return Stub.json({})

    Stub.request(
      :course, :get, '/sections',
      query:
        {
          course_id: report_job.task_scope,
          include_alternatives: true,
          published: true,
        }
    ).to_return Stub.json([])

    Stub.request(
      :course, :get, '/sections',
      query:
        {
          course_id: '',
          include_alternatives: true,
          published: true,
        }
    ).to_return Stub.json([])

    Stub.request(
      :course, :get, '/enrollments',
      query:
        {
          course_id: report_job.task_scope,
          per_page: 50,
          deleted: true,
        }
    ).to_return Stub.json([])

    Stub.request(
      :course, :get, '/enrollments',
      query:
        {
          course_id: '',
          per_page: 50,
          deleted: true,
        }
    ).to_return Stub.json([])

    Stub.request(
      :course, :get, '/enrollments',
      query:
        {
          course_id: '',
          per_page: 1,
          deleted: true,
        }
    ).to_return Stub.json([])

    Stub.request(
      :course, :get, '/enrollments',
      query:
        {
          course_id: '',
          per_page: 1000,
          deleted: true,
        }
    ).to_return Stub.json([])

    Stub.request(:account, :get)
      .to_return Stub.json({
        users_url: '/users',
      })

    Stub.request(
      :course, :get, '/items',
      query: {
        course_id: report_job.task_scope,
        content_type: 'video',
        was_available: true,
      }
    )
  end

  around do |example|
    report_job.with_tmp_directory(&example)
  end

  before do
    base_requests
  end

  context 'a CSV file is generated' do
    before do
      course_report.generate!
    end

    it 'generates one CSV file' do
      expect(course_report.files.count).to eq 1
      expect(course_report.files.names.first).to end_with '.csv'
    end

    it 'the CSV file has correct headers' do
      file = File.open(Rails.root.join("tmp/#{report_job.id}/#{course_report.files.names.first}"))
      headers = CSV.read(file, headers: true).headers

      expect(headers).to contain_exactly('User Pseudo ID', 'Enrollment Date', 'First Enrollment', 'User created', 'Language', 'Age Group', 'Enrollment Delta in Days', 'Forum Posts', 'Forum Threads', 'Reactivated', 'Reactivated Submission Date', 'Confirmation of Participation', 'Record of Achievement', 'Qualified Certificate', 'Course Completed', 'Un-enrolled', 'Quantile', 'Top Performance', 'Items Visited', 'Items Visited Percentage', 'Points', 'Points Percentage', 'Course Code')
    end
  end
end
