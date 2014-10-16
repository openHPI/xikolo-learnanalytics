Rails.application.routes.draw do
  
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)
  namespace :lanalytics do

    #  Managing domain model
    get 'snapshot', to: 'snapshot#snapshot'

    # Tracking user event
    post 'log', to: 'tracking#track'
    post 'track', to: 'tracking#track'
    # post 'bulk_track', to: 'tracking#bulk_track'
  

  end

end
