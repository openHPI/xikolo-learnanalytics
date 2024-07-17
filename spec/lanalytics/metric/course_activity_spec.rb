# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lanalytics::Metric::CourseActivity do
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:start_time) { 2.weeks.ago.to_s }
  let(:end_time) { Time.zone.now.to_s }

  describe '#query' do
    subject(:query) do
      described_class.query user_id:, course_id:, start_date: start_time, end_date: end_time
    end

    it 'sums the two metrics' do
      allow(Lanalytics::Metric::PinboardActivity).to receive(:query).and_return(count: 50)
      allow(Lanalytics::Metric::VisitCount).to receive(:query).and_return(count: 10)
      expect(query[:count]).to eq 35
    end
  end
end
