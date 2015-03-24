Rails.application.routes.draw do
  root to: 'application#welcome'

  # root :to => 'users#index'
  resources :user_sessions
  resources :users

  get 'login' => 'user_sessions#new', :as => :login
  post 'logout' => 'user_sessions#destroy', :as => :logout

  resources :research_cases, :defaults => { :format => 'html' } do
    member do

      post '/add_contributer', to: 'research_cases#add_contributer'
      get 'access_datasource/:datasource_key', to: 'research_cases#access_datasource'
      post 'access_datasource/:datasource_key', to: 'research_cases#datasource_accessed'

    end
  end

  get '/datasources', to: 'datasources#index', as: 'datasources'


  # Download routes
  get 'download/neo4j_shell_zip'

  defaults format: 'json' do
    resources :system_info, only: [:show]
    post 'query' => 'query#show'
  end
end
