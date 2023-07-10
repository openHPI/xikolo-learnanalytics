# frozen_string_literal: true

require 'rails_helper'

describe ProfileFields do
  subject(:fields) { profile_config.for(profile) }

  let(:full_name) do
    {
      'name' => 'full_name',
      'title' => {
        'en' => 'Full Name',
      },
      'type' => 'CustomTextField',
      'values' => ['Max Muster'],
    }
  end
  let(:gender) do
    {
      'name' => 'gender',
      'title' => {
        'en' => 'Gender',
      },
      'type' => 'CustomSelectField',
      'values' => %w[male],
    }
  end
  let(:city) do
    {
      'name' => 'city',
      'title' => {
        'en' => 'City',
      },
      'type' => 'CustomTextField',
      'values' => %w[Berlin],
    }
  end
  let(:sap_id) do
    {
      'name' => 'sap_id',
      'title' => {
        'en' => 'SAP ID',
      },
      'type' => 'CustomTextField',
      'values' => %w[12345678],
    }
  end
  let(:languages) do
    {
      'name' => 'languages',
      'title' => {
        'en' => 'Languages',
      },
      'type' => 'CustomSelectField',
      'values' => %w[de en fr],
    }
  end

  let(:profile) do
    {
      'user_id' => '9b954287-672a-4c49-8d07-d4c3d8d70d19',
      'fields' => [full_name, gender, city, sap_id, languages],
    }
  end

  before do
    create(:profile_field_configuration, name: 'sap_id', sensitive: false, omittable: true)
    create(:profile_field_configuration, name: 'full_name', sensitive: true, omittable: false)
  end

  describe '#[]' do
    context 'pseudonymized' do
      let(:profile_config) { ProfileFieldConfiguration.pseudonymized }

      it 'exposes normal fields' do
        expect(fields['gender']).to eq 'male'
      end

      it 'hides fields marked as sensitive' do
        expect(fields['full_name']).to be_nil
      end

      it 'hides field marked as omittable' do
        expect(fields['sap_id']).to be_nil
      end
    end

    context 'de_pseudonymized' do
      let(:profile_config) { ProfileFieldConfiguration.de_pseudonymized }

      it 'exposes normal fields' do
        expect(fields['gender']).to eq 'male'
      end

      it 'exposes fields marked as sensitive' do
        expect(fields['full_name']).to eq '"Max Muster"'
      end

      it 'hides field marked as omittable' do
        expect(fields['sap_id']).to be_nil
      end
    end
  end

  describe '#values' do
    subject { super().values }

    context 'pseudonymized' do
      let(:profile_config) { ProfileFieldConfiguration.pseudonymized }

      it { is_expected.to match_array %w[male "Berlin" de;en;fr] } # rubocop:disable Lint/PercentStringArray
    end

    context 'de_pseudonymized' do
      let(:profile_config) { ProfileFieldConfiguration.de_pseudonymized }

      it { is_expected.to contain_exactly('male', '"Max Muster"', '"Berlin"', 'de;en;fr') }
    end
  end

  describe '#titles' do
    subject { super().titles }

    context 'pseudonymized' do
      let(:profile_config) { ProfileFieldConfiguration.pseudonymized }

      it { is_expected.to match_array %w[Gender City Languages] }
    end

    context 'de_pseudonymized' do
      let(:profile_config) { ProfileFieldConfiguration.de_pseudonymized }

      it { is_expected.to contain_exactly('Full Name', 'Gender', 'City', 'Languages') }
    end
  end
end
