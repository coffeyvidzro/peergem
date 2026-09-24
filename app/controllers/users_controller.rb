# frozen_string_literal: true

class UsersController < Auth::BaseController
  before_action :require_session!

  def show
    return if performed?

    render json: { user: user_json(current_session.user) }
  end

  def update
    return if performed?

    current_session.user.update!(user_params)
    render json: { user: user_json(current_session.user) }
  end

  def destroy
    return if performed?

    current_session.user.deactivate!
    head :no_content
  end

  private

  def user_params
    params.permit(:name)
  end
end
