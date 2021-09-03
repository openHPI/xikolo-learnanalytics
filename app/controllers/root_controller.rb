# frozen_string_literal: true

class RootController < ApplicationController
  respond_to :json

  def index
    render json: rfc6570_routes.transform_keys {|n| "#{n}_url" }
  end
end
