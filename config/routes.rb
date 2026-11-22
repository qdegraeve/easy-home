Rails.application.routes.draw do
  resource :session
  resource :notification_settings, only: [ :edit, :update ]
  resources :push_devices, only: :create
  resource :test_notification, only: :create
  get "configurations/android_v1", to: "configurations#android_v1", as: :android_v1_configuration
  resources :passwords, param: :token

  resources :households, only: [ :index, :new, :create, :edit, :update ] do
    resource :selection, only: :create, module: :households
    resources :locations, only: :create
  end
  resources :locations, only: [ :edit, :update, :destroy ]
  resources :address_suggestions, only: :index
  # The three sections of the app (UX review): Aujourd'hui (root), Maison, Journal; and the settings.
  get "house", to: "house#show", as: :house
  resource :journal, only: :show, controller: "journal"
  resource :settings, only: :show
  resources :plants do
    resource :archive, only: [ :create, :destroy ], module: :plants
    resources :tasks, only: [ :new, :create, :edit, :update, :destroy ], module: :plants
    resources :photos, only: [ :create, :show, :edit, :update, :destroy ], module: :plants do
      # This photo becomes the face of the plant.
      resource :cover, only: :create, controller: "/plants/covers"
    end
    resources :analyses, only: [ :new, :create, :show ], module: :plants do
      member do
        post :accept_species
        post :accept_watering
        post "actions/:index/accept", action: :accept_action, as: :accept_action, constraints: { index: /\d+/ }
      end
      resources :questions, only: :create, controller: "analysis_questions" do
        post :ask_again, on: :member
      end
    end
  end
  resources :task_occurrences, only: [] do
    resource :completion, only: [ :create, :destroy ], module: :task_occurrences
    resource :postponement, only: [ :create, :destroy ], module: :task_occurrences
  end
  # Several occurrences at once: "Arroser · 4" on the home page, and the "Annuler" of a toast.
  resource :task_occurrences_batch_completion, only: [ :create, :destroy ], path: "task_occurrences/completions",
                                               controller: "task_occurrences/batch_completions"
  namespace :today do
    # Detail of the watering line of the home page: the plants to water, to uncheck those not done.
    resource :watering, only: :show
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#show"
end
