class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :require_login

  before_action :set_new_user_for_registration

  skip_before_action :require_login, only: [:welcome]

  def welcome
    return unless current_user

    redirect_to research_cases_path
  end

  private

  def set_new_user_for_registration
    return if current_user

    @user_for_registration = User.new
  end

  def not_authenticated
    redirect_to root_path, alert: "Please login first"
  end
end
