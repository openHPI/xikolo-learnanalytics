require 'rails_helper'

describe ProfileFields do

  let!(:full_name) {
    {
      'name' =>'full_name',
      'title' => {
        'en' => 'Full Name'
      },
      'type' => 'CustomTextField',
      'values' => %w(Max\ Muster)
    }
  }
  let!(:gender) {
    {
      'name' =>'gender',
      'title' => {
        'en' => 'Gender'
      },
      'type' => 'CustomSelectField',
      'values' => %w(male)
    }
  }
  let!(:city) {
    {
      'name' =>'city',
      'title' => {
        'en' => 'City'
      },
      'type' => 'CustomTextField',
      'values' => %w(Berlin)
    }
  }
  let!(:sap_id) {
    {
      'name' =>'sap_id',
      'title' => {
        'en' => 'SAP ID'
      },
      'type' => 'CustomTextField',
      'values' => %w(12345678)
    }
  }

  let!(:profile) do
    {
      'user_id' => '9b954287-672a-4c49-8d07-d4c3d8d70d19',
      'fields' => [full_name, gender, city, sap_id]
    }
  end

  before do
    FactoryBot.create :profile_field_configuration, name: 'sap_id', sensitive: false, omittable: true
    FactoryBot.create :profile_field_configuration, name: 'full_name', sensitive: true, omittable: false
  end

  subject { ProfileFields.new(profile, deanonymized) }

  describe '#fields' do
    subject { super().fields }

    context 'anonymized' do
      let(:deanonymized) { false }
      it { is_expected.to match_array [gender, city] }
    end

    context 'deanonymized' do
      let(:deanonymized) { true }
      it { is_expected.to match_array [full_name, gender, city] }
    end
  end

  describe '#values' do
    subject { super().values }

    context 'anonymized' do
      let(:deanonymized) { false }
      it { is_expected.to match_array %w(male "Berlin") }
    end

    context 'deanonymized' do
      let(:deanonymized) { true }
      it { is_expected.to match_array %w(male "Max\ Muster" "Berlin") }
    end
  end

  describe '#titles' do
    subject { super().titles }

    context 'anonymized' do
      let(:deanonymized) { false }
      it { is_expected.to match_array %w(Gender City) }
    end

    context 'deanonymized' do
      let(:deanonymized) { true }
      it { is_expected.to match_array %w(Full\ Name Gender City) }
    end
  end

end
