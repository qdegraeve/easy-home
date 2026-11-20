Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  resources :households, only: [ :index, :new, :create, :edit, :update ] do
    resource :selection, only: :create, module: :households
    resources :locations, only: :create
  end
  resources :locations, only: :destroy
  resources :address_suggestions, only: :index
  resources :plants, except: :index do
    resource :archive, only: [ :create, :destroy ], module: :plants
    resources :tasks, only: [ :new, :create, :edit, :update, :destroy ], module: :plants
    resources :photos, only: [ :create, :show, :update, :destroy ], module: :plants
    resources :analyses, only: [ :new, :create, :show ], module: :plants do
      member do
        post :accept_species
        post :accept_watering
        post "actions/:index/accept", action: :accept_action, as: :accept_action, constraints: { index: /\d+/ }
      end
    end
  end
  resources :task_occurrences, only: [] do
    resource :completion, only: [ :create, :destroy ], module: :task_occurrences
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#show"
end
