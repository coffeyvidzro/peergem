# frozen_string_literal: true

class SessionSerializer
  def self.call(session, current_session:, token: nil, include_location: false)
    payload = {
      id: session.public_id,
      is_current: session.id == current_session&.id,
      ip_address: session.ip_address&.to_s,
      user_agent: session.user_agent,
      expires_at: session.expires_at.iso8601,
      created_at: session.created_at.iso8601
    }
    payload[:last_active_at] = session.last_seen_at&.iso8601 if include_location
    payload[:location] = Geoip::Locate.call(session.ip_address) if include_location
    payload[:token] = token if token
    payload
  end
end