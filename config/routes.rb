# frozen_string_literal: true

Rails.application.routes.draw do
  defaults format: 'json' do
    root to: 'root#index'

    resources :system_info, only: [:show]

    # metrics

    get 'metrics/:name', to: 'metrics#show', as: :metric
    get 'metrics', to: 'metrics#index'

    # reports

    resources :report_jobs, only: %i[index show create update destroy]
    resources :report_types, only: %i[index]

    # statistics

    resources :course_statistics, only: %i[index show]
  end
end
