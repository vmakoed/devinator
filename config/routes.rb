Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Session management routes
  resources :sessions do
    member do
      get :workspace
    end

    # Nested resources for session-specific functionality
    resources :jql_queries, except: [:show] do
      collection do
        post :validate
      end
    end
    resources :tickets, only: [:index, :show]
    resources :recommendations, only: [:index, :show, :update]
    resources :assignments, only: [:index, :create, :show]
  end

  # Defines the root path route ("/")
  root "sessions#index"
end
