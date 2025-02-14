# frozen_string_literal: true

Rails.application.routes.draw do
  defaults format: :json do
    # Metrics
    get 'metrics/:name', to: 'metrics#show', as: :metric
    get 'metrics', to: 'metrics#index'

    # Reports
    resources :report_jobs, only: %i[index show create update destroy]
    resources :report_types, only: %i[index]

    # Statistics
    resources :course_statistics, only: %i[index show]

    resources :system_info, only: %i[show]
    root to: 'root#index'
  end
end
