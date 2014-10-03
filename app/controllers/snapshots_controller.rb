require 'rest_client'

class SnapshotsController < ApplicationController

  def trigger_snapshot

    lanalytics_datasources = [
      'http://localhost:3300',
      'http://localhost:3100'
    ]

    @trigger_snapshot_response_json = []

    lanalytics_datasources.each do | lanalytics_datasource_url |
      full_lanalytics_datasource_url = "#{lanalytics_datasource_url}/lanalytics/snapshot"
      response = RestClient.get(full_lanalytics_datasource_url)
      if not response.code == 200
        @trigger_snapshot_response_json << { datasource: full_lanalytics_datasource_url, status: "ERROR" }
      else
        @trigger_snapshot_response_json << { datasource: full_lanalytics_datasource_url, status: "OK" }
      end
    end

    render json: @trigger_snapshot_response_json

    # If we want to do something more extended ...
    #while not lanalytics_datasources.empty?
    #  lanalytics_datasource_url = lanalytics_datasources.shift
    #
    #  response = RestClient.get("#{lanalytics_datasource_url}/lanalytics/snapshot")
    #  if not response.code == 200
    #    lanalytics_datasources.push(lanalytics_datasource_url)
    #  end
    #end


  end

end
