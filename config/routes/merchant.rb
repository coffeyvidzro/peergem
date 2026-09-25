get "merchants", to: "merchants#index"
post "merchants", to: "merchants#create"

scope "/merchants/:merchant_id", as: :merchant do
  get "/", to: "merchants#show"
  patch "/", to: "merchants#update"
  get "memberships", to: "merchant_memberships#index"
  patch "memberships/:membership_id", to: "merchant_memberships#update"
  delete "memberships/:membership_id", to: "merchant_memberships#destroy"
  delete "membership", to: "merchant_memberships#leave"
  get "invitations", to: "merchant_invitations#index"
  post "invitations", to: "merchant_invitations#create"
  delete "invitations/:invitation_id", to: "merchant_invitations#destroy"
  post "invitations/:invitation_id/resend", to: "merchant_invitations#resend"
  get "api_keys", to: "api_keys#index"
  post "api_keys", to: "api_keys#create"
  patch "api_keys/:api_key_id", to: "api_keys#update"
  post "api_keys/:api_key_id/rotate", to: "api_keys#rotate"
  delete "api_keys/:api_key_id", to: "api_keys#destroy"
end

post "merchant_invitations/accept", to: "merchant_invitations#accept"
