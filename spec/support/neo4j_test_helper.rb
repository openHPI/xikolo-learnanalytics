class Neo4jTestHelper
  # include Assertion
  def self.clean_database
    rest_response = MultiJson.load(RestClient.get('http://localhost:8474/db/data/schema/index'), symbolize_keys: true)
    rest_response.each do | index_meta_info |
        Neo4j::Session.query("DROP INDEX ON :#{index_meta_info[:label]}(resource_uuid)")
    end
    Neo4j::Session.query("MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r;")
    
    raise "Neo4j not cleaned completely" if Neo4j::Session.query.match(:n).pluck(:n).length > 0

    Lanalytics::Processing::Processor::Neo4jIndexProcessor.reset
  end
end