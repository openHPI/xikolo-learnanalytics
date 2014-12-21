class Neo4jDatasource < Datasource

  def channels
    channels = []

    channels << neo4j_browser_channel
    channels << neo4j_remote_shell
    
    channels << Channel.new('Neo4j Rest Interface', %q{Here is the rest interface ...}, "http://neo4j.com/developer/guide-neo4j-browser/")
    channels << Channel.new('Neo4j Dummy Client', %q{This is dummy client.}, "http://neo4j.com/developer/guide-neo4j-browser/")
  end

  private
  def neo4j_browser_channel
    WebAppChannel.new('Neo4j Browser', %q{
The Neo4j Browser

The default Neo4j Server has a powerful, customizable data visualization tool based on the built-in D3.js library. In the following video, we demonstrate how to style nodes and relationships in the Neo4j’s Browser visualization, and how to set colors, sizes, and titles. We then discuss the Graph-Style-Sheet (GRASS) and how you can download, update, and reset the styling information.

        }, "http://neo4j.com/developer/guide-neo4j-browser/", "http://localhost:7474/browser/")
  end

  def neo4j_remote_shell

    RemoteShellChannel.new('Neo4j Shell', %q{
The Neo4j Shell

Neo4j shell is a command-line shell for running Cypher queries. There’s also commands to get information about the database. In addition, you can browse the graph, much like how the Unix shell along with commands like cd, ls and pwd can be used to browse your local file system.
},
  "http://neo4j.com/docs/stable/shell.html")
  end

end
