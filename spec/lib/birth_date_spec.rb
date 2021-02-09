# frozen_string_literal:true

require 'spec_helper'

RSpec.describe BirthDate do
  let(:b_date) { described_class.new('2000-01-05') }
  let(:current_date) { DateTime.parse('2020-02-04') }

  describe '#initialize' do
    context 'when birth date is in the future' do
      it 'does not raise an error' do
        expect { described_class.new('2050-11-11') }.not_to raise_error
      end
    end

    context 'when birth date is nil' do
      it 'does not parse date of birth date' do
        expect { described_class.new(nil) }.not_to raise_error
      end
    end
  end

  describe '#age_group_at' do
    context 'when current date is provided' do
      it 'calculates age group from current date argument' do
        expect(b_date.age_group_at(current_date)).to eq '20-29'
      end
    end

    context 'when current date is nil' do
      it 'returns blank value' do
        expect(b_date.age_group_at(nil)).to eq ''
      end
    end

    context 'when birthday has not yet passed' do
      it 'calculates age group correctly' do
        expect(described_class.new('2001-08-31').age_group_at(DateTime.parse('2021-02-05'))).to eq '<20'
      end
    end
  end

  context 'when birth date is nil' do
    let(:b_date) { described_class.new(nil) }

    it 'returns blank instead of calculating age group' do
      expect(b_date.age_group_at(current_date)).to eq ''
    end
  end
end
