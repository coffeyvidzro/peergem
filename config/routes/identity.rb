namespace :auth do
  post "start", to: "transactions#create"
  post "email/send", to: "email_challenges#create"
  post "email/resend", to: "email_challenges#resend"
  post "email/verify", to: "email_challenges#verify"
  post "password/login", to: "passwords#login"
  post "password/forgot", to: "passwords#forgot"
  post "password/reset", to: "passwords#reset"
  post "password/change", to: "passwords#change"
end

get "sessions", to: "sessions#index"
delete "sessions/others", to: "sessions#others"
get "sessions/:id", to: "sessions#show"
delete "sessions/:id", to: "sessions#destroy"

get "user", to: "users#show"
patch "user", to: "users#update"
delete "user", to: "users#destroy"
