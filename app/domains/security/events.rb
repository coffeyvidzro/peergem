# frozen_string_literal: true

module Security
  class Events
    def self.record(
      event_type,
      user: nil,
      merchant: nil,
      ip_address: nil,
      user_agent: nil,
      metadata: {},
      now: Time.current
    )
      SecurityEvent.create!(
        event_type: event_type,
        user: user,
        merchant: merchant,
        ip_address: ip_address,
        user_agent: user_agent,
        metadata: metadata,
        occurred_at: now
      )
    end
  end
end
