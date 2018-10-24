Rails.application.routes.draw do
  defaults format: 'json' do
    root to: 'root#index'

    resources :system_info, only: [:show]

    # metrics

    get 'metrics/:name', to: 'metrics#show', as: :metric
    get 'metrics', to: 'metrics#index'

    # clusters

    get 'cluster_jobs/:id', to: 'cluster_jobs#show', as: :cluster_job
    post 'cluster_jobs', to: 'cluster_jobs#create'

    resources :cluster_dimensions, only: [:index]

    resources :cluster_groups do
      resource :recomputing_job, to: 'cluster_groups#recomputing_job', only: [:create]

      resources :teacher_actions, only: [:show, :index, :create] do
        resource :recomputing_job, to: 'teacher_actions#recomputing_job', only: [:create]
      end
    end

    # reports

    resources :report_jobs, only: [:index, :show, :create, :update, :destroy]

    # statistics

    resources :course_statistics, only: [:index, :show]

    # qc rules

    resources :qc_rules, only: [:index, :show, :create, :update]
    resources :qc_recommendations, only: [:index, :show]
    resources :qc_alerts, only: [:index, :show, :create, :update] do
     collection do
       post :ignore
     end
    end
    resources :qc_alert_statuses, only: [:index, :show, :create]
    resources :qc_course_statuses, only: [:index, :show, :create, :update]
  end
end
