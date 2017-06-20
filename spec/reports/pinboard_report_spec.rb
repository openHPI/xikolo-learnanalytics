require 'spec_helper'

describe 'Pinboard Report' do
  let!(:report) { FactoryGirl.create :job, :pinboard_report }

  subject { report.generate!(report_params) }
  let(:report_params) { {} }

  around do |example|
    report.in_tmp_directory(&example)
  end

  before do
    Stub.service(
      :course,
      course_url: 'http://localhost:3300/courses/{id}'
    )

    Stub.service(
      :pinboard,
      answers_url: 'http://localhost:3500/answers',
      comments_url: 'http://localhost:3500/comments'
    )

    Stub.request(
      :course, :get, "/courses/#{report.task_scope}"
    ).to_return Stub.json(
      id: report.task_scope,
      course_code: 'report_course'
    )

    Stub.request(
      :pinboard, :get, '/questions',
      query: { course_id: report.task_scope, per_page: 50 }
    ).to_return Stub.json([])
  end

  it 'generates one CSV file' do
    subject
    expect(subject.files).to have(1).item
    expect(subject.files.first.to_s).to end_with '.csv'
  end
end
