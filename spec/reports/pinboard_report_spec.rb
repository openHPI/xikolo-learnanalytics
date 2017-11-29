require 'spec_helper'

describe 'Pinboard Report' do
  let!(:report) { FactoryBot.create :job, :pinboard_report }

  subject { report.generate!(report_params) }
  let(:report_params) { {} }

  around do |example|
    report.with_tmp_directory(&example)
  end

  before do
    Stub.service(
      :course,
      course_url: 'http://localhost:3300/courses/{id}'
    )

    Stub.service(
      :pinboard,
      answers_url: 'http://localhost:3500/answers',
      comments_url: 'http://localhost:3500/comments',
      questions_url: 'http://localhost:3500/questions'
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
    expect(subject.files.count).to eq 1
    expect(subject.files.names.first).to end_with '.csv'
  end
end
