Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "/auth/register", to: "auth/registrations#create"
      post "/auth/login", to: "auth/sessions#create"

      resources :tasks, only: [ :index, :show, :create, :update, :destroy ]
    end
  end
end
