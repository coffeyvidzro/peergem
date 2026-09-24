Rails.application.routes.draw do
  namespace :auth do
    post "start", to: "transactions#create"
    post "email/send", to: "email_challenges#create"
    post "email/resend", to: "email_challenges#resend"
    post "email/verify", to: "email_challenges#verify"
    post "password/login", to: "passwords#login"
    post "password/enroll", to: "passwords#enroll"
    post "password/forgot", to: "passwords#forgot"
    post "password/reset", to: "passwords#reset"
  end

  resources :sessions, only: %i[index show destroy] do
    delete :destroy_all, on: :collection, path: ""
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  mount OkComputer::Engine, at: "/health"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
