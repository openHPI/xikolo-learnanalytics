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

    # statistics

    resources :course_statistics, only: %i[index show]
    resources :section_conversions, param: :course_id, only: [:show]

    # qc rules

    resources :qc_rules, only: %i[index show create update]
    resources :qc_recommendations, only: %i[index show]
    resources :qc_alerts, only: %i[index show create update] do
      collection do
        post :ignore
      end
    end
    resources :qc_alert_statuses, only: %i[index show create]
    resources :qc_course_statuses, only: %i[index show create update]
  end
end
