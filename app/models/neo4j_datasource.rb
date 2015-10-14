class Neo4jDatasource < Datasource
  attr_reader :neo4j_server_url

  def neo4j_server_url
    self.settings[:db_url]    
  end

  def username
    self.settings[:username]    
  end

  def password
    self.settings[:password]    
  end

  def authenticate_user(user)
    new_user_post_url = URI.join(self.neo4j_server_url, '/auth/add-user-ro')
    new_user_post_url.user= self.username if self.username
    new_user_post_url.password= self.password if self.password
    RestClient.post(new_user_post_url.to_s, user: "#{user.username}:{user.crypted_password}")
  end

  def setup_channels(current_user)
    @channels = []

    @channels << neo4j_browser_channel(current_user)
    @channels << neo4j_remote_shell
    @channels << neoclipse_gui
    @channels << rneo_documentation
    
    # @channels << Channel.new('Neo4j Rest Interface', %q{Here is the rest interface ...}, "http://neo4j.com/developer/guide-neo4j-browser/")
  end


  private
  def neo4j_browser_channel(current_user)
    neo4j_browser_url = URI.join(self.neo4j_server_url, "browser")
    neo4j_browser_url.userinfo = "#{current_user.username}:#{current_user.crypted_password}"
    WebAppChannel.new(
      'Neo4j Browser',
      'The default Neo4j Server has a powerful, customizable data visualization tool based on the built-in D3.js library. In the following video, we demonstrate how to style nodes and relationships in the Neo4j’s Browser visualization, and how to set colors, sizes, and titles. We then discuss the Graph-Style-Sheet (GRASS) and how you can download, update, and reset the styling information.',
      'http://neo4j.com/developer/guide-neo4j-browser/',
      neo4j_browser_url
#       , %Q{
# <p> Your credentials are:
#   <ul>
#     <li>Username: #{current_user.username}</li>
#     <li>Password: #{current_user.crypted_password}</li>
#   </ul>
# </p>
# }
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

  def rneo_documentation
    WebDocumentationChannel.new(
      'RNeo4j',
      'An R package that allows you to easily populate a Neo4j graph database from your R environment.',
      "http://nicolewhite.github.io/RNeo4j",
      %Q{
In your R environment, execute the following:<br/>
<pre>
install.packages("devtools")
devtools::install_github("nicolewhite/RNeo4j")
</pre>
<hr />
Once installed, you need to load the module 'RNeo4j' and establish a connection to the Neo4j server:
<pre>
library(RNeo4j)
graph = startGraph("#{URI.join(self.neo4j_server_url, "/db/data/")}")
</pre>

<hr />

Then, you can access the database within R environment <u><a href="http://nicolewhite.github.io/RNeo4j/docs/">with these functions</a></u>.
      }
    )
  end

end
