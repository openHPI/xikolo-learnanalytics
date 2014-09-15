require 'action_controller'

module Lanalytics
  module LanalyticsControllerFilter

    # before_filter :add_lanalytics_filter

    def add_lanalytics_filter
      if current_user
        # Setting a meta lanaytics variable via gon, e.g. the current user so that it can be retrieved by tracking js code on the page
        gon.lanalytics = {
          :current_user => current_user
        }
      end
    end

  end
end
