class Neo4jTestHelper
  # TODO:: include Assertion
  def self.clean_database

    nosql_neo4j_datasource = Lanalytics::Processing::DatasourceManager.get_datasource('exp_graph_schema_neo4j')

    rest_response = MultiJson.load(RestClient.get('http://localhost:8474/db/data/schema/index'), symbolize_keys: true)
    rest_response.each do | index_meta_info |
      nosql_neo4j_datasource.exec do | session |
        session.query("DROP INDEX ON :#{index_meta_info[:label]}(resource_uuid)")
      end
    end

    nosql_neo4j_datasource.exec do | session |
      session.query("MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r;")
    end
    
    nosql_neo4j_datasource.exec do | session |
      raise "Neo4j not cleaned completely" if session.query.match(:n).pluck(:n).length > 0
    end

    # Lanalytics::Processing::Processor::Neo4jIndexProcessor.reset
  end
end