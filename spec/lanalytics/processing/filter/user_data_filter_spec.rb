# require 'rails_helper'

# # describe Lanalytics::Processing::AmqpProcessing do
# describe Lanalytics::Processing::Filter::UserDataFilter, :broken => true do

#   describe '(without custom fields)' do

#     before(:each) do
#       @original_hash = FactoryGirl.attributes_for(:amqp_user).with_indifferent_access
#       @data_filter = Lanalytics::Processing::Filter::UserDataFilter.new
#     end

#     it 'should should create :USER resource with correct properties' do
#       processed_resources = []
#       @data_filter.filter(@original_hash, processed_resources)

#       expect(processed_resources.length).to eq(1)
#       processed_resource = processed_resources.first
#       expect(processed_resource).to be_a(Lanalytics::Model::StmtResource)
#       expect(processed_resource.type).to eq(:USER)
#       expect(processed_resource.uuid).to eq(@original_hash[:id])

#       expect(processed_resource.properties).to include(email: "kevin.cool@example.com", language: "en", born_at: "1985-04-24T00:00:00.000Z", created_at:"2014-10-20T19:56:31.268Z")
#     end
  
#     it "should not modify the original hash" do
#       old_hash = @original_hash
#       expect { @data_filter.filter(@original_hash, []) }.to_not raise_error
#       expect(@original_hash).to be(old_hash)
#       expect(@original_hash).to eq(old_hash)
#     end

#   end

#   describe '(with custom fields)' do
#     before(:each) do
#       @original_hash = FactoryGirl.attributes_for(:amqp_user_with_fields).with_indifferent_access
#       @data_filter = Lanalytics::Processing::Filter::UserDataFilter.new
#     end

#     it 'should convert (custom) field properties into resource properties' do
#       processed_resources = []
#       @data_filter.filter(@original_hash, processed_resources)

#       expect(processed_resources.length).to eq(1)
#       processed_resource = processed_resources.first
#       expect(processed_resource).to be_a(Lanalytics::Model::StmtResource)
#       expect(processed_resource.type).to eq(:USER)
#       expect(processed_resource.uuid).to eq(@original_hash[:id])
#       expect(processed_resource.properties).to include(affiliation: "Hasso Plattner Institute")
#       expect(processed_resource.properties).to_not include(:country)
#       expect(processed_resource.properties).to include(city: "Potsdam")
#       expect(processed_resource.properties).to include(gender: "male")

#       # Should also contain other properties
#       expect(processed_resource.properties).to include(language: "en", born_at: "1985-04-24T00:00:00.000Z", created_at:"2014-10-20T19:56:31.268Z")
#     end
#   end


# end
