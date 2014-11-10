require 'rails_helper'

describe Lanalytics::Processing::Processor::Neo4jIndexProcessor do

  after(:each) do
    Neo4j::Session.query("DROP INDEX ON :USER(resource_uuid)")
    Neo4j::Session.query("DROP INDEX ON :COURSE(resource_uuid)")
    Neo4j::Session.query("MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r;")
    expect(Neo4j::Session.query.match(:n).pluck(:n).length).to eq(0)
  end

  it 'understand index response' do
    Neo4j::Session.query("CREATE INDEX ON :COURSE(resource_uuid)")
    Neo4j::Session.query("CREATE INDEX ON :USER(resource_uuid)")

    # stub_request(:get, 'http://localhost:8474/db/data/index').to_return(status: 200,
    #   body: [
    #     { property_keys: [ "resource_uuid" ], label: "USER" },
    #     { property_keys: [ "resource_uuid" ], label: "COURSE" }
    # ].to_json)

    neo4j_index_processor = Lanalytics::Processing::Processor::Neo4jIndexProcessor.new
    @original_hash = double('original_hash')
    resource = FactoryGirl.build(:stmt_resource)
    neo4j_index_processor.process(@original_hash, [resource], { processing_action: Lanalytics::Processing::ProcessingAction::CREATE })

    expect(neo4j_index_processor.available_indexed_node_types).to be_an(Array)
    expect(neo4j_index_processor.available_indexed_node_types.length).to eq(3)
    expect(neo4j_index_processor.available_indexed_node_types).to include(:USER, :COURSE, :SOMERESOURCE)

    rest_response = MultiJson.load(RestClient.get('http://localhost:8474/db/data/schema/index'), symbolize_keys: true)
    expect(rest_response.length).to eq(3)
    expect(rest_response).to include({ property_keys: [ "resource_uuid" ], label: "SOMERESOURCE" })
  end

end
