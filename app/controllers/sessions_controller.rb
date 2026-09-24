# frozen_string_literal: true

class SessionsController < ApiController
  before_action :require_session!

  def index
    return if performed?

    sessions = Sessions::List.call(user: current_session.user)
    render json: { sessions: sessions.map { |session| SessionSerializer.new(session, current_session: current_session).as_json } }
  end

  def show
    return if performed?

    session = owned_session
    render json: {
      session: SessionSerializer.new(session, current_session: current_session).detailed_json(
        location: Geoip::Locate.call(ip_address: session.ip_address)
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

    Sessions::RevokeAll.call(user: current_session.user)
    head :no_content
  end

  private

  def owned_session
    session = Session.find_by_public_id!(params[:id])
    raise ActiveRecord::RecordNotFound unless SessionPolicy.new(current_session.user, session).show?

    session
  end

  def not_found
    render json: { error: { code: "not_found", message: "Session was not found" } }, status: :not_found
  end
end
