class WelcomeController < ApplicationController
  def current_user
    return {
      id: "1234567890"
    }
  end

  def index
  end
end
