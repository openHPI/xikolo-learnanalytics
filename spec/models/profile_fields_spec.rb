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
  let!(:languages) {
    {
      'name' =>'languages',
      'title' => {
        'en' => 'Languages'
      },
      'type' => 'CustomSelectField',
      'values' => %w(de en fr)
    }
  }

  let!(:profile) do
    {
      'user_id' => '9b954287-672a-4c49-8d07-d4c3d8d70d19',
      'fields' => [full_name, gender, city, sap_id, languages]
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
      it { is_expected.to match_array [gender, city, languages] }
    end

    context 'deanonymized' do
      let(:deanonymized) { true }
      it { is_expected.to match_array [full_name, gender, city, languages] }
    end
  end

  describe '#values' do
    subject { super().values }

    context 'anonymized' do
      let(:deanonymized) { false }
      it { is_expected.to match_array %w(male "Berlin" de;en;fr) }
    end

    context 'deanonymized' do
      let(:deanonymized) { true }
      it { is_expected.to match_array %w(male "Max\ Muster" "Berlin" de;en;fr) }
    end
  end

  describe '#titles' do
    subject { super().titles }

    context 'anonymized' do
      let(:deanonymized) { false }
      it { is_expected.to match_array %w(Gender City Languages) }
    end

    context 'deanonymized' do
      let(:deanonymized) { true }
      it { is_expected.to match_array %w(Full\ Name Gender City Languages) }
    end
  end

end
