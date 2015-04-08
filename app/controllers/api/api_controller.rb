class Api::ApiController < ApplicationController
  protect_from_forgery with: :null_session

  # TODO secure controller when researcher interface is published
  skip_before_action :require_login, only: [:index]

  def index
    render json: rfc6570_routes.select{|r| r =~ /api/}.map{|n,r| ["#{n.to_s.gsub('api_', '')}_url", r]}.to_h
  end
end
