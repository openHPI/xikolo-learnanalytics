class PostgresqlDatasource < Datasource

  def database
    return self.settings[:database]
  end

  def port
    return self.settings[:port]
  end

  def setup_channels(current_user)
    @channels = []

    @channels << team_postgresql_browser_channel(current_user)
    # channels << neo4j_remote_shell

    # channels << Channel.new('Neo4j Rest Interface', %q{Here is the rest interface ...}, "http://neo4j.com/developer/guide-neo4j-browser/")
    # channels << Channel.new('Neo4j Dummy Client', %q{This is dummy client.}, "http://neo4j.com/developer/guide-neo4j-browser/")
  end

  private
  def team_postgresql_browser_channel(current_user)
    return WebAppChannel.new(
      'PostgreSQL Studio',
      'All you need is a modern web browser, from there you can simplify your PostgreSQL Development, run SQL queries, and manage your database.',
      "http://www.postgresqlstudio.org/support/documentation/",
      "http://localhost:8080/PgStudio.jsp",
      %Q{
        <p>
          <strong>Use the following credentials for logging into the database:</strong>
        </p>
        <ul>
          <li>Database Host: #{self.settings.fetch(:host, 'lanalytics.openhpi.de')}</li>
          <li>Database Port: #{self.settings.fetch(:port, 5432)}</li>
          <li>Database Name: #{self.database}</li>
          <li>Username: #{current_user.email}</li>
          <li>Password: &emsp;Type in your password for the LAnalytics Service</li>
        </ul>
      }
    )
  end


end
