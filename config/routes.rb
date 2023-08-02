# frozen_string_literal: true

Rails.application.routes.draw do
  get 'search/show'
  get 'auth/index'
  post 'auth/create'
  # post '/metrics', to: 'metrics#index' # used for load testing
  post 'translate', to: 'translate#translate'

  resources :uploaded_images, only: %i[new edit create update]
  resources :searches, only: %i[show]
  post '/searches/:id/sort_and_filter_results', to: 'searches#sort_and_filter_results'
  post '/searches/:id/trigger_full_analysis', to: 'searches#trigger_full_analysis'
  post '/searches/:id/full_results', to: 'searches#full_results'

  root 'uploaded_images#new'
end
