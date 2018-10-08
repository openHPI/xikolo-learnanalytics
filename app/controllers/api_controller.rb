class ApiController < ApplicationController
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
