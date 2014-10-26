require 'rails_helper'

describe Lanalytics::Processing::Filter::AnonymousDataFilter do

  before(:each) do
    @original_hash = FactoryGirl.attributes_for(:amqp_user).with_indifferent_access
    @data_filter = Lanalytics::Processing::Filter::AnonymousDataFilter.new
    @processed_resources = [ Lanalytics::Model::StmtResource.new(@original_hash[:id], :USER, {
        language: "en",
        born_at: "1985-04-24T00:00:00.000Z",
        email: "kevin.cool@example.com",
        display_name: "Kevin Cool",
        first_name: "Kevin",
        last_name: "Cool Jr."
      }) ]
  end


  it 'should remove all sensitive data properties' do
    @data_filter.filter(@original_hash, @processed_resources)
    expect(@processed_resources.length).to eq(1)
    processed_resource = @processed_resources.first
    expect(processed_resource.properties).to include(language: "en", born_at: "1985-04-24T00:00:00.000Z")
    expect(processed_resource.properties.keys).to_not include(:email, :display_name, :first_name, :last_name)
  end

  it "should not modify the original hash" do
    old_hash = @original_hash
    @data_filter.filter(@original_hash, @processed_resources)
    expect(@original_hash).to be(old_hash)
    expect(@original_hash).to eq(old_hash)
  end

end