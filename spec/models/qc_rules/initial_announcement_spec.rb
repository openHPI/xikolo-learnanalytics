require 'spec_helper'

describe QcRules::InitialAnnouncement do
  let!(:qc_rule2) { FactoryBot.create :qc_rule }
  let!(:test_course) { FactoryBot.build :test_course, {id: '00000001-3100-4444-9999-000000000002'} }
  let!(:normal_course) { FactoryBot.build :test_course, {id: '00000001-3100-4444-9999-000000000022'} }
  let!(:course_little_enrollments) { FactoryBot.build :test_course, {id: '00000001-3100-4444-9999-000000000003', end_date: 3.days.ago.iso8601} }
  let!(:test_course2) { FactoryBot.build :test_course, {id: '00000001-3100-4444-9999-000000000015'} }

  subject { described_class.new qc_rule2 }

  let!(:total_pages) { 101 }
  let(:headers) do
    {
      'X-Total-Pages' => '102',
      'X-Total-Count' => '10'
    }
  end
  let(:headers2) do
    {
      'X-Total-Pages' => '99',
      'X-Total-Count' => '10'
    }
  end
  before do
    Stub.service(
      :course,
      enrollments_url: '/enrollments'
    )
    Stub.request(
      :course, :get, '/enrollments',
      query: { course_id: test_course['id'], per_page: 1 }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000004' }
    ], headers: headers)
    Stub.request(
      :course, :get, '/enrollments',
      query: { course_id: course_little_enrollments['id'], per_page: 1 }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000001' }
    ], headers: headers2)
    Stub.request(
      :course, :get, '/enrollments',
      query: { course_id: test_course2['id'], per_page: 1 }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000001' }
    ], headers: headers)
    Stub.request(
      :course, :get, '/enrollments',
      query: { course_id: normal_course['id'], per_page: 1 }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000001' }
    ], headers: headers)

    Stub.service(
      :news,
      news_index_url: 'http://news.xikolo.tld/news',
      news_url: 'http://news.xikolo.tld/news/{id}'
    )
    Stub.request(
      :news, :get, '/news',
      query: { course_id: test_course['id'], published: 'true' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000002', sending_state: 1 }
    ])
    Stub.request(
      :news, :get, '/news',
      query: { course_id: test_course2['id'], published: 'true' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000003' }
    ])
    Stub.request(
      :news, :get, '/news',
      query: { course_id: course_little_enrollments['id'], published: 'true' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000003', sending_state: 0 }
    ])
    Stub.request(
      :news, :get, '/news',
      query: { course_id: normal_course['id'], published: 'true' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000003', sending_state: 1, publish_at: 4.days.ago }
    ])
  end

  describe '#run' do
    subject { super().run course }
    let(:course) { test_course }

    context 'when no start date is given' do
      before { test_course['start_date'] = nil }

      it 'should not create an alert' do
        expect { subject }.to_not change { QcAlert.count }
      end
    end

    context 'when too few enrollments' do
      let(:course) { course_little_enrollments }

      it 'should not create an alert' do
        expect { subject }.to_not change { QcAlert.count }
      end
    end

    context 'when course is over' do
      before { test_course['end_date'] = 3.days.ago.iso8601 }

      it 'should not create an alert' do
        expect { subject }.to_not change { QcAlert.count }
      end
    end

    context 'when sending state is 0' do
      let(:course) { test_course2 }

      it 'should create an alert' do
        expect { subject }.to change { QcAlert.count }
                                .from(0)
                                .to(1)
      end
    end

    context 'when course is over' do
      let(:course) { normal_course }

      it 'should not create an alert' do
        expect { subject }.to_not change { QcAlert.count }
      end
    end
  end
end
