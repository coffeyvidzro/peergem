# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :authenticate_account!

  def index
    sessions = Current.user.sessions.active.order(created_at: :desc)
    render json: {
      sessions: sessions.map { |session| SessionSerializer.call(session, current_session: Current.auth_session) }
    }
  end

  def show
    render json: {
      session: SessionSerializer.call(
        find_session,
        current_session: Current.auth_session,
        include_location: true
      )
    }
  end

  def destroy
    ::Sessions::Revoke.call(session: find_session)
    head :no_content
  end

  def destroy_all
    now = Time.current
    count = Current.user.sessions.where(revoked_at: nil).update_all(revoked_at: now)
    Security::Events.record(
      "session.revoked_all",
      user: Current.user,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      metadata: { count: count },
      now: now
    )
    head :no_content
  end

  private

  def find_session
    id = AuthSession.id_from_public_id!(params.expect(:id))
    Current.user.sessions.find(id)
  end
end