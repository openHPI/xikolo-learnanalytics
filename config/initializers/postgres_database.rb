postgres_database_config_file = "#{Rails.root}/config/postgres_database.yml"
if File.exists?(postgres_database_config_file)

  postgres_database_config = YAML.load_file(postgres_database_config_file).with_indifferent_access
  postgres_database_config = postgres_database_config[Rails.env] || postgres_database_config

  begin
    $postgres_connection = ConnectionPool.new(size: 1) { PG.connect(postgres_database_config) }
    # conn = PG.connect(postgres_database_config)
  rescue Exception => any_error
    Rails.logger.error "No Postgres connection could be created for database #{postgres_database_config[:db_name]} ."
    # raise 'No Neo4j::Session could be created. Plz have a look at the configuration ...' unless session
  end
  
else
  Rails.logger.info "No postgres database configuration available in #{postgres_database_config_file}."
end

