# frozen_string_literal: true

class SessionsController < Auth::BaseController
  before_action :require_session!

  def index
    return if performed?

    sessions = current_session.user.sessions.active.order(created_at: :desc)
    render json: { sessions: sessions.map { |session| session_summary_json(session) } }
  end

  def show
    return if performed?

    session = owned_session
    render json: {
      session: session_summary_json(session).merge(
        last_active_at: session.last_seen_at&.iso8601,
        location: session_location(session)
      )
    }
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
    session = Session.find_by_public_id!(params[:id])
    raise ActiveRecord::RecordNotFound unless session.user_id == current_session.user_id

    session
  end

  def session_summary_json(session)
    {
      id: session.public_id,
      is_current: session.id == current_session.id,
      ip_address: session.ip_address&.to_s,
      user_agent: session.user_agent,
      expires_at: session.expires_at.iso8601,
      created_at: session.created_at.iso8601
    }
  end

  def session_location(session)
    reader = Rails.application.config.x.geoip.reader
    return unless reader && session.ip_address

    result = reader.city(session.ip_address.to_s)
    [ result.city.name, result.country.name ].compact_blank.join(", ").presence
  rescue StandardError
    nil
  end

  def not_found
    render json: { error: { code: "not_found", message: "Session was not found" } }, status: :not_found
  end
end
