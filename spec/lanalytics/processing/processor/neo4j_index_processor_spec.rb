# require 'rails_helper'

# describe Lanalytics::Processing::Processor::Neo4jIndexProcessor do

#   before(:each) do
#     Neo4jTestHelper.clean_database
#   end

#   it 'understand index response' do
#     rest_response = MultiJson.load(RestClient.get('http://localhost:8474/db/data/schema/index'), symbolize_keys: true)
#     Neo4j::Session.query("CREATE INDEX ON :COURSE(resource_uuid)")
#     Neo4j::Session.query("CREATE INDEX ON :USER(resource_uuid)")

#     neo4j_index_processor = Lanalytics::Processing::Processor::Neo4jIndexProcessor.new
#     @original_hash = double('original_hash')
#     resource = FactoryGirl.build(:stmt_resource)
#     neo4j_index_processor.process(@original_hash, [resource], { processing_action: Lanalytics::Processing::Action::CREATE })

#     expect(neo4j_index_processor.available_indexed_node_types).to be_an(Array)
#     expect(neo4j_index_processor.available_indexed_node_types.length).to eq(3)
#     expect(neo4j_index_processor.available_indexed_node_types).to include(:USER, :COURSE, :SOMERESOURCE)

#     rest_response = MultiJson.load(RestClient.get('http://localhost:8474/db/data/schema/index'), symbolize_keys: true)
#     expect(rest_response.length).to eq(3)
#     expect(rest_response).to include({ property_keys: [ "resource_uuid" ], label: "SOMERESOURCE" })
#   end

# end
