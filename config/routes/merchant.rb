resources :merchants, only: %i[index create]

scope "/merchants/:merchant_id", as: :merchant do
  get "/", to: "merchants#show"
  patch "/", to: "merchants#update"
  resources :memberships, controller: "merchant_memberships", only: %i[index update destroy]
  resources :invitations, controller: "merchant_invitations", only: %i[index create destroy]
end

post "merchant_invitations/accept", to: "merchant_invitations#accept"
