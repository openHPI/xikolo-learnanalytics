NEO4J_DATABASE_CONFIG_FILE = "#{Rails.root}/config/neo4j_database.yml"
if File.exists?(NEO4J_DATABASE_CONFIG_FILE)

  NEO4J_DATABASE_CONFIG = YAML.load_file(NEO4J_DATABASE_CONFIG_FILE).with_indifferent_access
  NEO4J_DATABASE_CONFIG = NEO4J_DATABASE_CONFIG[Rails.env] || NEO4J_DATABASE_CONFIG

  # Register a default Neo4j::Session for this applilcation
  neo4j_db_type = NEO4J_DATABASE_CONFIG[:db_type].to_sym
  neo4j_db_url = NEO4J_DATABASE_CONFIG[:db_url]
  session = Neo4j::Session.open(neo4j_db_type, neo4j_db_url)
  # if Rails.env.test?
  #   Rails.logger.warn "No Neo4j::Session could be created. But the test continues"
  # else
  raise 'No Neo4j::Session could be created. Plz have a look at the configuration ...' unless session
end