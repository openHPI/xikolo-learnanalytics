# frozen_string_literal: true

require 'spec_helper'

describe QcRules::LowCourseCommunication do
  subject(:rule) { described_class.new qc_rule }

  let!(:qc_rule) { FactoryBot.create :qc_rule }

  let!(:test_course) do
    FactoryBot.build :test_course,
      id: '00000001-3100-4444-9999-000000000002',
      start_date: 11.days.ago.iso8601,
      end_date: 5.days.from_now.iso8601,
      status: 'active'
  end

  let!(:test_course2) do
    FactoryBot.build :test_course,
      id: '00000001-3100-4444-9999-000000000003',
      start_date: 11.days.ago.iso8601,
      end_date: 5.days.from_now.iso8601,
      status: 'active'
  end

  let(:headers) do
    {
      'X-Total-Pages' => '102',
      'X-Total-Count' => '102',
    }
  end

  before do
    Stub.request(:course, :get)
      .to_return Stub.json(enrollments_url: '/enrollments')
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: test_course['id'], per_page: '1'}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000004'},
    ], headers: headers)
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: test_course2['id'], per_page: '1'}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000004'},
    ], headers: headers)
    Stub.request(:news, :get)
      .to_return Stub.json(
        news_index_url: 'http://news.xikolo.tld/news',
        news_url: 'http://news.xikolo.tld/news/{id}',
      )
    Stub.request(
      :news, :get, '/news',
      query: {course_id: test_course['id'], published: 'true', per_page: '1', page: '1'}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000002', publish_at: 11.days.ago},
    ])
    Stub.request(
      :news, :get, '/news',
      query: {course_id: test_course2['id'], published: 'true', per_page: '1', page: '1'}
    ).to_return Stub.json([
      {id: '00000001-3100-4444-9999-000000000002', publish_at: 9.days.ago},
    ])
  end

  describe '#run' do
    subject(:run) { rule.run course }

    context 'when announcement is too old' do
      let(:course) { test_course }

      it 'creates an alert' do
        expect { run }.to change(QcAlert, :count).from(0).to(1)
      end
    end

    context 'when announcement is not too old' do
      let(:course) { test_course2 }

      it 'does not create an alert' do
        expect { run }.not_to change(QcAlert, :count)
      end
    end
  end
end
