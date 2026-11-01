Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[new create]

  namespace :api, defaults: {format: :json} do
    namespace :v1 do
      resource :session, only: %i[create destroy]
      resource :registration, only: :create
      resource :me, controller: :me, only: %i[show update destroy] do
        # Both keyed by the other user's id.
        resources :follow_requests, only: %i[index destroy] do
          post :approve, on: :member
        end
        resources :followers, only: :destroy
        resources :saved_recipes, only: :index
      end
      resources :users, only: %i[index show] do
        resource :follow, only: %i[create destroy]
        resources :followers, only: :index
        resources :following, only: :index
      end
      resources :recipes, except: %i[new edit] do
        resource :save, only: %i[create destroy]
        resource :fork, only: :create
      end
      resource :feed, only: :show
      resource :household, only: %i[show update]
      get "meal_plans/:date", to: "meal_plans#show", as: :meal_plan
      post "meal_plans/:date/copy", to: "meal_plans#copy", as: :copy_meal_plan
      resources :planned_meals, only: %i[create update destroy]
      resources :direct_uploads, only: :create
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#show"
end
