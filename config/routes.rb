Rails.application.routes.draw do
  root "missions#index"

  resources :missions, only: [ :index, :create, :show ] do
    member do
      get :query
      patch :query
      get :analyze
      post :save_selection
      get :assign
      post :assign
    end

    resources :tickets, only: [] do
      collection do
        get :preview
        post :confirm
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pva_service_worker
end
