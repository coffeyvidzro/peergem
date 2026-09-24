class ApplicationController < ActionController::Base
  include BearerAuthentication
  include Pundit::Authorization

  # Browser & Caching configuration (Rails 8 defaults)
  allow_browser versions: :modern
  stale_when_importmap_changes

  # Error handling
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  def pundit_user
    AuthorizationContext.new(
      user: Current.user,
      merchant: Current.merchant,
      membership: Current.membership,
      auth_session: Current.auth_session
    )
  end

  def render_forbidden
    respond_to do |format|
      format.html { redirect_to root_path, alert: "You are not authorized to perform this action." }
      format.json { render json: { error: "forbidden" }, status: :forbidden }
    end
  end
end