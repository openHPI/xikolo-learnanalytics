# frozen_string_literal: true

require 'spec_helper'

describe QcRules::DifficultSelftest do
  subject(:rule) { described_class.new(qc_rule) }

  let!(:qc_rule) { create(:qc_rule) }
  let!(:course) do
    build(
      :test_course,
      id: '00000001-3100-4444-9999-000000000002',
      start_date: 5.days.ago.iso8601,
      end_date: 5.days.from_now.iso8601,
      status: 'active',
      forum_is_locked: nil,
    )
  end

  before do
    Stub.request(:course, :get)
      .to_return Stub.json(items_url: '/items')
    Stub.request(
      :course, :get, '/items',
      query: {
        course_id: course['id'],
        content_type: 'quiz',
        exercise_type: 'main,bonus,selftest',
        published: true,
      }
    ).to_return Stub.json([
      {
        id: '00000001-3100-4444-9999-000000000004',
        content_id: '00000001-3100-4444-9999-000000000004',
      },
    ])

    Stub.request(:quiz, :get)
      .to_return Stub.json(
        question_url: '/questions/{id}',
        submission_statistic_url: '/submission_statistics/{id}',
      )
    Stub.request(
      :quiz, :get,
      '/submission_statistics/00000001-3100-4444-9999-000000000004',
      query: {embed: 'questions_base_stats'}
    ).to_return Stub.json(
      total_submissions: 2,
      total_submissions_distinct: 2,
      max_points: 10,
      avg_points: 7.5,
      questions_base_stats: [
        {
          id: '00000001-3100-4444-9999-000000000007',
          max_points: 10.0,
          avg_points: 7.5,
          correct_submissions: 10,
          partly_correct_submissions: 10,
          incorrect_submissions: 10,
        },
        {
          id: '00000001-3100-4444-9999-000000000008',
          max_points: 10.0,
          avg_points: 7.5,
          correct_submissions: 20,
          partly_correct_submissions: 0,
          incorrect_submissions: 0,
        },
        {
          id: '00000001-3100-4444-9999-000000000009',
          max_points: 10.0,
          avg_points: 7.5,
          correct_submissions: 60,
          partly_correct_submissions: 40,
          incorrect_submissions: 0,
        },
        {
          id: '00000001-3100-4444-9999-000000000010',
          max_points: 10.0,
          avg_points: 7.5,
          correct_submissions: 80,
          partly_correct_submissions: 20,
          incorrect_submissions: 0,
        },
      ],
    )
    Stub.request(
      :quiz, :get, '/questions/00000001-3100-4444-9999-000000000007'
    ).to_return Stub.json(id: 2, text: 'Foo')
    Stub.request(
      :quiz, :get, '/questions/00000001-3100-4444-9999-000000000009'
    ).to_return Stub.json(id: 2, text: 'Bar')
  end

  describe '#run' do
    subject(:run) { rule.run(course) }

    it 'creates two alerts' do
      expect { run }.to change(QcAlert, :count).from(0).to(2)
    end
  end
end
