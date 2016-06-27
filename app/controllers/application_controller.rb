class ApplicationController < ActionController::API
  extend Responders::ControllerMethod
  include ActionController::RespondWith
  include ActionController::StrongParameters
  include ActionController::ImplicitRender

  def api_version
    1
  end
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
end
