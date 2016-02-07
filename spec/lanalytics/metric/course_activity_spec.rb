require 'rails_helper'

RSpec.describe Lanalytics::Metric::CourseActivity do
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:start_time) { 2.weeks.ago.to_s }
  let(:end_time) { Time.now.to_s }

  describe '#query' do
    subject { described_class.query user_id, course_id, start_time, end_time, nil, nil, nil }

    it 'sums the two metrics' do
      expect(Lanalytics::Metric::PinboardActivity).to receive(:query).and_return(count: 50)
      expect(Lanalytics::Metric::VisitCount).to receive(:query).and_return(count: 10)
      expect(subject[:count]).to eq 35
    end
  end
end
