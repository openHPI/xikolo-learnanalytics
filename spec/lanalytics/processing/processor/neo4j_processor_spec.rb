require 'rails_helper'

describe Lanalytics::Processing::Processor::Neo4jProcessor do

  before(:each) do
    @neo4j_processor = Lanalytics::Processing::Processor::Neo4jProcessor
  end

  after(:each) do
    Neo4j::Session.query("MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r;")
    expect(Neo4j::Session.query.match(:n).pluck(:n).length).to eq(0)
  end

  it 'should deal with multiple lanalytics resources' do

  end

  it 'should not create additional lanalytics resources' do
    @neo4j_processor.process
  end

  it 'should do nothing when no lanalytics entities defined' do

  end

  it "should not modify the original hash" do
    old_hash = @original_hash
    expect { @data_filter.filter(@original_hash, []) }.to_not raise_error
    expect(@original_hash).to be(old_hash)
    expect(@original_hash).to eq(old_hash)
  end

  describe '(dealing with Resources)' do

  end

  describe '(dealing with ContinuousRelationship)' do
    
  end

  describe '(dealing with Experience Statement)' do

  end

end
