# require 'rails_helper'

# describe Lanalytics::Processing::Processor::Neo4jProcessor do

#   before(:each) do
#     @neo4j_processor = Lanalytics::Processing::Processor::Neo4jProcessor.new
#     @original_hash = double('original_hash')
#     # expect(@original_hash).to_not receive()
#   end

#   before(:each) do
#     Neo4jTestHelper.clean_database
#   end

#   # it 'should deal with multiple lanalytics resources' do

#   # end

#   # it 'should not create additional lanalytics resources' do
#   #   @neo4j_processor.process
#   # end

#   # it 'should do nothing when no lanalytics entities defined' do

#   # end

#   # it "should not modify the original hash" do
#   #   old_hash = @original_hash
#   #   expect { @neo4j_processor.process(@original_hash, []) }.to_not raise_error
#   #   expect(@original_hash).to be(old_hash)
#   #   expect(@original_hash).to eq(old_hash)
#   # end

#   describe '(dealing with Resources)' do

#     it 'should create a new resource' do
#       resource = FactoryGirl.build(:stmt_resource)
#       @neo4j_processor.process(@original_hash, [resource], { processing_action: Lanalytics::Processing::Action::CREATE })

#       result = Neo4j::Session.query.match(r: {resource.type.to_sym.upcase => {resource_uuid: resource.uuid }}).pluck(:r)
#       expect(result.length).to eq(1)
#       expected_node = result.first
#       expect(expected_node.labels).to include(resource.type.to_sym.upcase)
#       expect(expected_node.props).to include(resource_uuid: resource.uuid)
#       expect(expected_node.props.keys).to include(:propertyA, :propertyB)
#     end

#     it 'should destroy a resource' do
#       resource = FactoryGirl.build(:stmt_resource)
#       Neo4j::Node.create({ resource_uuid: resource.uuid }.merge(resource.properties), :SOMERESOURCE)

#       @neo4j_processor.process(@original_hash, [resource], { processing_action: Lanalytics::Processing::Action::DESTROY })

#       result = Neo4j::Session.query.match(r: resource.type.to_sym.upcase).pluck(:r)
#       expect(result.length).to eq(0)
#     end

#   end

#   describe '(dealing with ContinuousRelationship)' do
#     it 'should create a new relationship' do
#       # resource = FactoryGirl.build(:stmt_resource)
#       # @neo4j_processor.process(@original_hash, [resource], { processing_action: Lanalytics::Processing::Action::CREATE })

#       # result = Neo4j::Session.query.match(r: {resource.type.to_sym.upcase => {resource_uuid: resource.uuid }}).pluck(:r)
#       # expect(result.length).to eq(1)
#       # expected_node = result.first
#       # expect(expected_node.labels).to include(resource.type.to_sym.upcase)
#       # expect(expected_node.props).to include(resource_uuid: resource.uuid)
#       # expect(expected_node.props.keys).to include(:propertyA, :propertyB)
#     end
#   end

#   describe '(dealing with Experience Statement)' do

#   end

# end
