Rails.application.routes.draw do
  
  namespace :lanalytics do
    post 'log', to: 'tracking#track'
    post 'track', to: 'tracking#track'
    # post 'bulk_track', to: 'tracking#bulk_track'
  end

end
