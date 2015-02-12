class DownloadController < ApplicationController

  def neo4j_shell_zip
    send_file("#{Rails.root}/public/downloads/neo4j-shell-2.1.5.zip")
  end

end