Rails.application.routes.draw do
  #root to: 'application#welcome'

  defaults format: 'json' do
    root to: 'root#index'
    get 'query', to: 'query#show', as: :query
    get 'query/job_results',  to: 'query#job_results', as: :job_results

    get 'query/available_cluster_dimensions', as: :available_cluster_dimensions
    post 'query/clustering_job', to: 'query#clustering_job', as: :clustering_job
    resources :cluster_groups do
      resource :recomputing_job, to: 'cluster_groups#recomputing_job', only: [:create]

      resources :teacher_actions, only: [:show, :index, :create] do
        resource :recomputing_job, to: 'teacher_actions#recomputing_job', only: [:create]
      end
    end

    resources :system_info, only: [:show]

    resources :jobs
    resources :course_statistics
    resources :system_info, only: [:show]
    resources :qc_rules
    resources :qc_recommendations
    resources :qc_alerts  do
     collection do
       post :ignore
     end
    end
    resources :qc_alert_statuses
    resources :qc_course_statuses
  end
end
