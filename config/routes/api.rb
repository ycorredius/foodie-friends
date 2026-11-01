namespace :api, defaults: {format: :json} do
  namespace :v1 do
    resources :auths, only: :create
    delete "/auths", to: "auths#destroy"
    resource :me, controller: :me, only: :show
    resource :user, only: :create do
      resources :friends, only: %i[create destroy index]
    end
    namespace :user do
      resources :recipes, only: [:index]
      resources :favorites, only: %i[create destroy]
    end
    resources :recipes, only: %i[show index]
  end
end
