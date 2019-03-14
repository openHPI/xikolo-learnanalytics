require 'spec_helper'

describe 'Pinboard Report' do
  let!(:report_job) { FactoryBot.create :report_job, :pinboard_report, options: {'include_collab_spaces' => true} }

  subject { report_job.generate! }

  around do |example|
    report_job.with_tmp_directory(&example)
  end

  before do
    Stub.service(
      :course,
      course_url: 'http://localhost:3300/courses/{id}'
    )
    Stub.request(
      :course, :get, "/courses/#{report_job.task_scope}"
    ).to_return Stub.json(
      id: report_job.task_scope,
      course_code: 'report_course'
    )

    Stub.service(
      :collabspace,
      collab_spaces_url: '/collab_spaces'
    )
    Stub.request(
      :collabspace, :get, '/collab_spaces',
      query: { course_id: report_job.task_scope }
    ).to_return Stub.json([
      {id: collab_space_id}
    ])

    Stub.service(
      :pinboard,
      answers_url: 'http://localhost:3500/answers',
      comments_url: 'http://localhost:3500/comments',
      questions_url: 'http://localhost:3500/questions'
    )
    Stub.request(
      :pinboard, :get, '/questions',
      query: { course_id: report_job.task_scope, per_page: 50 }
    ).to_return Stub.json([])
    Stub.request(
      :pinboard, :get, '/questions',
      query: { learning_room_id: collab_space_id, per_page: 50 }
    ).to_return Stub.json([])
  end
  let(:collab_space_id) { SecureRandom.uuid }

  it 'generates one CSV file' do
    subject
    expect(subject.files.count).to eq 1
    expect(subject.files.names.first).to end_with '.csv'
  end
end
