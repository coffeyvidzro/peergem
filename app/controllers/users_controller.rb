# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_account!
  rescue_from Users::Deactivate::ConfirmationRequiredError, with: :render_confirmation_required
  rescue_from Users::Deactivate::ReauthenticationRequiredError, with: :render_reauthentication_required
  rescue_from Users::Deactivate::MerchantOwnershipRequiredError, with: :render_merchant_ownership_required

  def show
    render_user
  end

  def update
    Users::UpdateProfile.call(user: Current.user, name: user_params.fetch(:name))
    render_user
  end

  def destroy
    Users::Deactivate.call(
      user: Current.user,
      session: Current.auth_session,
      confirmation: params.expect(:confirmation),
      password: params[:password],
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    head :no_content
  end

  private

  def user_params
    params.expect(user: [ :name ])
  end

  def render_user
    render json: { user: UserSerializer.call(Current.user) }
  end

  def render_confirmation_required
    render json: { error: "confirmation_required" }, status: :unprocessable_content
  end

  def render_reauthentication_required
    render json: { error: "reauthentication_required" }, status: :forbidden
  end
end