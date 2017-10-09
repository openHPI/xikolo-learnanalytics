require 'spec_helper'

describe QcRules::LowCourseCommunication do

  subject { described_class.new qc_rule2 }

  let!(:qc_rule2) { FactoryGirl.create :qc_rule }
  let!(:test_course) { FactoryGirl.build :test_course,
                                         {id: '00000001-3100-4444-9999-000000000002',
                                          start_date: 11.days.ago.iso8601,
                                          end_date: 5.days.from_now.iso8601,
                                          status: 'active'} }
  let!(:test_course2) { FactoryGirl.build :test_course,
                                         {id: '00000001-3100-4444-9999-000000000003',
                                          start_date: 11.days.ago.iso8601,
                                          end_date: 5.days.from_now.iso8601,
                                          status: 'active'} }
  let(:headers) do
    {
      'X-Total-Pages' => '102',
      'X-Total-Count' => '102'
    }
  end
  before do
    Stub.service(
      :course,
      enrollments_url: '/enrollments'
    )
    Stub.request(
      :course, :get, '/enrollments',
      query: { course_id: test_course['id'], per_page: '1' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000004' }
    ], headers: headers)
    Stub.request(
      :course, :get, '/enrollments',
      query: { course_id: test_course2['id'], per_page: '1' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000004' }
    ], headers: headers)
  end

  before do
    Stub.service(
      :news,
      news_index_url: 'http://news.xikolo.tld/news',
      news_url: 'http://news.xikolo.tld/news/{id}'
    )
    Stub.request(
      :news, :get, '/news',
      query: { course_id: test_course['id'], published: 'true', per_page: '1', page: '1' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000002', publish_at: 11.days.ago }
    ])
    Stub.request(
      :news, :get, '/news',
      query: { course_id: test_course2['id'], published: 'true', per_page: '1', page: '1' }
    ).to_return Stub.json([
      { id: '00000001-3100-4444-9999-000000000002', publish_at: 9.days.ago }
    ])
  end

  describe '#run' do
    subject { super().run course }

    context 'when announcement is too old' do
      let(:course) { test_course }

      it 'should create an alert' do
        expect { subject }.to change { QcAlert.count }
                                .from(0)
                                .to(1)
      end
    end

    context 'when announcement is not too old' do
      let(:course) { test_course2 }

      it 'should not create an alert' do
        expect { subject }.to_not change { QcAlert.count }
      end
    end
  end
end
