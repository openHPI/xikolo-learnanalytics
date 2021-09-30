# frozen_string_literal: true

require 'spec_helper'

describe QcRules::InitialAnnouncement do
  subject(:rule) { described_class.new qc_rule }

  let!(:qc_rule) { FactoryBot.create :qc_rule }
  let!(:test_course) { FactoryBot.build :test_course, {id: '00000001-3100-4444-9999-000000000002'} }
  let!(:course_little_enrollments) { FactoryBot.build :test_course, {id: '00000001-3100-4444-9999-000000000003', end_date: 3.days.ago.iso8601} }
  let!(:test_course2) { FactoryBot.build :test_course, {id: '00000001-3100-4444-9999-000000000015'} }

  let(:headers) do
    {
      'X-Total-Pages' => '102',
      'X-Total-Count' => '10',
    }
  end
  let(:headers2) do
    {
      'X-Total-Pages' => '99',
      'X-Total-Count' => '10',
    }
  end

  before do
    Stub.request(:course, :get)
      .to_return Stub.json(enrollments_url: '/enrollments')
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: test_course['id'], per_page: 1}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000004'},
    ], headers: headers)
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: course_little_enrollments['id'], per_page: 1}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000001'},
    ], headers: headers2)
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: test_course2['id'], per_page: 1}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000001'},
    ], headers: headers)

    Stub.request(:news, :get)
      .to_return Stub.json(
        news_index_url: 'http://news.xikolo.tld/news',
        news_url: 'http://news.xikolo.tld/news/{id}',
      )
    Stub.request(
      :news, :get, '/news',
      query: {course_id: test_course['id'], published: 'true'}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000002', sending_state: 1},
    ])
    Stub.request(
      :news, :get, '/news',
      query: {course_id: test_course2['id'], published: 'true'}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000003'},
    ])
    Stub.request(
      :news, :get, '/news',
      query: {course_id: course_little_enrollments['id'], published: 'true'}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000003', sending_state: 0},
    ])
  end

  describe '#run' do
    subject(:run) { rule.run course }

    let(:course) { test_course }

    context 'when no start date is given' do
      before { test_course['start_date'] = nil }

      it 'does not create an alert' do
        expect { run }.not_to change(QcAlert, :count)
      end
    end

    context 'when too few enrollments' do
      let(:course) { course_little_enrollments }

      it 'does not create an alert' do
        expect { run }.not_to change(QcAlert, :count)
      end
    end

    context 'when course is over' do
      before { test_course['end_date'] = 3.days.ago.iso8601 }

      it 'does not create an alert' do
        expect { run }.not_to change(QcAlert, :count)
      end
    end

    context 'when sending state is 0' do
      let(:course) { test_course2 }

      it 'creates an alert' do
        expect { run }.to change(QcAlert, :count).from(0).to(1)
      end
    end
  end
end
