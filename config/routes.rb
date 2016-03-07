Rails.application.routes.draw do
  root to: 'application#welcome'

  # root :to => 'users#index'
  resources :user_sessions
  resources :users

  get 'login',   to: 'user_sessions#new', as: :login
  post 'logout', to: 'user_sessions#destroy', as: :logout

  resources :research_cases, defaults: {format: 'html'} do
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
    namespace :api do
      root to: 'api#index'
      get 'query', to: 'query#show', as: :query
      get 'query/job_results',  to: 'query#job_results', as: :job_results

      get 'query/available_cluster_dimensions', as: :available_cluster_dimensions
      post 'query/clustering', to: 'query#clustering_job', as: :clustering_job

      resources :cluster_groups do
        resource :recomputing_job, to: 'cluster_groups#recomputing_job', only: [:create]

        resources :teacher_actions, only: [:show, :index, :create] do
          resource :recomputing_job, to: 'teacher_actions#recomputing_job', only: [:create]
        end
      end

    end
  end
end
