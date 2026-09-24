# frozen_string_literal: true

class UsersController < ApiController
  before_action :require_session!

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
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    head :no_content
  end

  private

  def user_params
    params.permit(:name)
  end
end
