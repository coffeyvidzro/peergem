# frozen_string_literal: true

class SessionSerializer
  def initialize(session, current_session:)
    @session = session
    @current_session = current_session
  end

  def as_json(*)
    {
      id: @session.public_id,
      is_current: @session.id == @current_session.id,
      ip_address: @session.ip_address&.to_s,
      user_agent: @session.user_agent,
      expires_at: @session.expires_at.iso8601,
      created_at: @session.created_at.iso8601
    }
  end

  def detailed_json(location:)
    as_json.merge(
      last_active_at: @session.last_seen_at&.iso8601,
      location: location
    )
  end
end
