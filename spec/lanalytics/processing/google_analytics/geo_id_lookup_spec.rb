require 'rails_helper'

describe Lanalytics::Processing::GoogleAnalytics::GeoIdLookup do

  before(:each) do
    location_criteria_file_path = Rails.root.join('spec', 'support', 'files', 'ga-location-criteria-example.csv')
    @geo_id_lookup = Lanalytics::Processing::GoogleAnalytics::GeoIdLookup.new(location_criteria_file_path)
  end

  it 'should return the correct geo id of a city' do
    geo_id = @geo_id_lookup.get('DE', 'Potsdam')
    expect(geo_id).to eq('1003886')
  end

  it 'should return country code, if city has no geo id' do
    geo_id = @geo_id_lookup.get('UK', 'Potsdam')
    expect(geo_id).to eq('UK')
  end

  it 'should ignore locations that are not marked as active' do
    geo_id = @geo_id_lookup.get('DE', 'Berlin')
    expect(geo_id).to eq('DE')
  end

  it 'should ignore locations that are not cities' do
    geo_id = @geo_id_lookup.get('DE', 'Berlin Tegel Airport')
    expect(geo_id).to eq('DE')
  end
end