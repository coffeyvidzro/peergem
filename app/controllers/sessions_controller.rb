# frozen_string_literal: true

class SessionsController < Auth::BaseController
  before_action :require_session!

  def index
    return if performed?

    sessions = current_session.user.sessions.active.order(created_at: :desc)
    render json: { sessions: sessions.map { |session| session_json(session) } }
  end

  def show
    return if performed?

    render json: { session: session_json(owned_session) }
  end

  def destroy
    return if performed?

    session = owned_session
    session.revoke! unless session.revoked?
    head :no_content
  end

  def destroy_all
    return if performed?

    current_session.user.sessions.active.update_all(revoked_at: Time.current)
    head :no_content
  end

  private

  def owned_session
    current_session.user.sessions.find(params[:id])
  end

  def session_json(session)
    {
      id: session.id,
      assurance: session.assurance,
      ip_address: session.ip_address,
      user_agent: session.user_agent,
      created_at: session.created_at.iso8601,
      expires_at: session.expires_at.iso8601,
      last_seen_at: session.last_seen_at&.iso8601,
      revoked_at: session.revoked_at&.iso8601,
      current: session.id == current_session.id
    }
  end

  def not_found
    render json: { error: { code: "not_found", message: "Session was not found" } }, status: :not_found
  end
end
