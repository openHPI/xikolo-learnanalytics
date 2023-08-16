# frozen_string_literal: true

require 'spec_helper'

describe Reports::PinboardReport do
  subject(:report) { report_job.generate! }

  let!(:report_job) { create(:report_job, :pinboard_report, options: {'include_collab_spaces' => true}) }

  let(:collab_space_id) { SecureRandom.uuid }

  around do |example|
    report_job.with_tmp_directory(&example)
  end

  before do
    Stub.request(:course, :get)
      .to_return Stub.json({course_url: 'http://course.xikolo.tld/courses/{id}'})
    Stub.request(
      :course, :get, "/courses/#{report_job.task_scope}"
    ).to_return Stub.json({
      id: report_job.task_scope,
      course_code: 'report_course',
    })

    Stub.request(:collabspace, :get)
      .to_return Stub.json({collab_spaces_url: '/collab_spaces'})
    Stub.request(
      :collabspace, :get, '/collab_spaces',
      query: {course_id: report_job.task_scope}
    ).to_return Stub.json([
      {id: collab_space_id},
    ])

    Stub.request(:pinboard, :get)
      .to_return Stub.json({
        answers_url: 'http://pinboard.xikolo.tld/answers',
        comments_url: 'http://pinboard.xikolo.tld/comments',
        questions_url: 'http://pinboard.xikolo.tld/questions',
      })
    Stub.request(
      :pinboard, :get, '/questions',
      query: {course_id: report_job.task_scope, per_page: 50}
    ).to_return Stub.json([])
    Stub.request(
      :pinboard, :get, '/questions',
      query: {learning_room_id: collab_space_id, per_page: 50}
    ).to_return Stub.json([])
  end

  it 'generates one CSV file' do
    report
    expect(report.files.count).to eq 1
    expect(report.files.names.first).to end_with '.csv'
  end
end
