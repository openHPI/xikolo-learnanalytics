require 'msgr'

class Lanalytics::TrackingController < ApplicationController
  respond_to :json 
  skip_before_action :add_lanalytics_filter
  skip_before_action :verify_authenticity_token
  
  def track
    exp_api_stmt = Lanalytics::Model::ExpApiStatement.new_from_json(params.to_h)
    Msgr.publish(exp_api_stmt.as_json, to: "lanalytics.event.stream")
    render json: { status: "ok" }
  end

  def bulk_track
  end

  private
  def log_params
    params.permit("actor", "verb", "object")
  end
end
