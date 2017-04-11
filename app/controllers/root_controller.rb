class RootController < ApplicationController
  respond_to :json

  def index
    render json: rfc6570_routes.map{|n, k| ["#{n}_url", k] }.to_h
  end

end
