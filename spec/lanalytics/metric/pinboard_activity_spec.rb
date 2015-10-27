require 'rails_helper'

RSpec.describe Lanalytics::Metric::PinboardActivity do
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:start_time) { 2.weeks.ago.to_s }
  let(:end_time) { Time.now.to_s }

  describe '#query' do
    subject { described_class.query user_id, course_id, start_time, end_time, nil }

    it 'sums the two metrics' do
      expect(Lanalytics::Metric::PinboardPostingActivity).to receive(:query).and_return(count: 10)
      expect(Lanalytics::Metric::PinboardWatchCount).to receive(:query).and_return(count: 100)
      expect(subject[:count]).to eq 30
    end
  end
end
