class Neo4jDatasource < Datasource
  attr_reader :neo4j_server_url

  def neo4j_server_url
    self.settings[:db_url]    
  end

  def channels
    channels = []

    channels << neo4j_browser_channel
    channels << neo4j_remote_shell
    channels << neoclipse_gui
    
    channels << Channel.new('Neo4j Rest Interface', %q{Here is the rest interface ...}, "http://neo4j.com/developer/guide-neo4j-browser/")
  end


  private
  def neo4j_browser_channel
    WebAppChannel.new(
      'Neo4j Browser',
      'The default Neo4j Server has a powerful, customizable data visualization tool based on the built-in D3.js library. In the following video, we demonstrate how to style nodes and relationships in the Neo4j’s Browser visualization, and how to set colors, sizes, and titles. We then discuss the Graph-Style-Sheet (GRASS) and how you can download, update, and reset the styling information.',
      "http://neo4j.com/developer/guide-neo4j-browser/",
      URI.join(self.neo4j_server_url, "browser")
    )
  end

  def neo4j_remote_shell
    Neo4jShellChannel.new(
      'Neo4j Shell',
      "Neo4j shell is a command-line shell for running Cypher queries. There's also commands to get information about the database. In addition, you can browse the graph, much like how the Unix shell along with commands like 'cd', ls and 'pwd' can be used to browse your local file system.",
      "http://neo4j.com/docs/stable/shell.html"
    )
  end

  def neoclipse_gui
    NeoclipseChannel.new(
      'Neoclipse',
      'Neoclipse is a subproject of Neo4j which aims to be a tool that supports the development of Neo4j applications. Main features are A) Visualizing the graph, B) Filtering the view by relationship types and C) Highlighting nodes / relationships in different ways.',
      "https://github.com/neo4j-contrib/neoclipse/wiki"
    )
  end

end
