# frozen_string_literal: true

class UsersController < ApiController
  before_action :require_session!
  rescue_from Users::Deactivate::ConfirmationRequiredError, with: :confirmation_required
  rescue_from Users::Deactivate::ReauthenticationRequiredError, with: :reauthentication_required
  rescue_from Users::Deactivate::MerchantOwnershipRequiredError, with: :merchant_ownership_required

  def show
    return if performed?

    render json: { user: UserSerializer.new(current_session.user).as_json }
  end

  def update
    return if performed?

    current_session.user.update!(user_params)
    render json: { user: UserSerializer.new(current_session.user).as_json }
  end

  def destroy
    return if performed?

    Users::Deactivate.call(
      user: current_session.user,
      confirmation: params[:confirmation],
      password: params[:password],
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    head :no_content
  end

  private

  def user_params
    params.permit(:name)
  end

  def merchant_ownership_required
    render json: {
      error: { code: "merchant_ownership_required", message: "Transfer merchant ownership before deactivating" }
    }, status: :conflict
  end

  def confirmation_required
    render json: { error: { code: "confirmation_required", message: "Confirmation must be DEACTIVATE" } },
      status: :unprocessable_content
  end

  def reauthentication_required
    render json: { error: { code: "reauthentication_required", message: "Current password is required" } },
      status: :forbidden
  end
end
