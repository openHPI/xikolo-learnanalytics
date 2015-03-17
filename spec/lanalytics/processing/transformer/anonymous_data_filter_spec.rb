require 'rails_helper'

describe Lanalytics::Processing::Transformer::AnonymousDataFilter do

  before(:each) do
    @original_hash = FactoryGirl.attributes_for(:amqp_user).with_indifferent_access
    @data_filter = Lanalytics::Processing::Transformer::AnonymousDataFilter.new
    @processing_units = [ Lanalytics::Processing::Unit.new(:USER, @original_hash) ]
  end


  it 'should remove all sensitive data properties' do

    @data_filter.transform(@original_hash, @processing_units, [], nil)

    expect(@processing_units.length).to eq(1)
    processing_unit = @processing_units.first
    expect(processing_unit.data).to include(language: "en", born_at: "1985-04-24T00:00:00.000Z")
    expect(processing_unit.data.keys).to_not include(:email, :display_name, :first_name, :last_name)
  end

  it "should not modify the original hash" do
    old_hash = @original_hash
    @data_filter.transform(@original_hash, @processing_units, [], nil)
    expect(@original_hash).to be(old_hash)
    expect(@original_hash).to eq(old_hash)
  end

end