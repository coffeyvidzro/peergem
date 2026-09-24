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

resource :user, only: %i[show update destroy]
