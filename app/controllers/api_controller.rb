class ApiController < ApplicationController
  protect_from_forgery with: :null_session

  # TODO secure controller when researcher interface is published
  skip_before_action :require_login, only: [:index]

  def index
    # Display all routes
    render json: rfc6570_routes.select { |route|
      route =~ /api/
    }.map { |name, route|
      route_name = name.to_s.gsub('api_', '')
      ["#{route_name}_url", route]
    }.to_h
  end
end
