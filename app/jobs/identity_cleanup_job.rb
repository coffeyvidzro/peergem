# frozen_string_literal: true

class IdentityCleanupJob < ApplicationJob
  queue_as :low

  AUTH_RETENTION = 7.days
  SESSION_RETENTION = 30.days
  SECURITY_EVENT_RETENTION = 1.year

  def perform(now: Time.current)
    auth_cutoff = now - AUTH_RETENTION
    session_cutoff = now - SESSION_RETENTION
    security_event_cutoff = now - SECURITY_EVENT_RETENTION

    deleted_challenges = AuthChallenge
      .where("created_at < ? AND (consumed_at IS NOT NULL OR expires_at < ?)", auth_cutoff, now)
      .delete_all
    deleted_transactions = AuthTransaction
      .where(state: %w[authenticated expired])
      .where("updated_at < ?", auth_cutoff)
      .delete_all
    deleted_sessions = AuthSession
      .where("created_at < ? AND (revoked_at IS NOT NULL OR expires_at < ?)", session_cutoff, now)
      .delete_all
    deleted_invitations = MerchantInvitation
      .where("created_at < ? AND (accepted_at IS NOT NULL OR revoked_at IS NOT NULL OR expires_at < ?)", auth_cutoff, now)
      .delete_all
    deleted_security_events = SecurityEvent.where("occurred_at < ?", security_event_cutoff).delete_all

    {
      auth_challenges: deleted_challenges,
      auth_transactions: deleted_transactions,
      auth_sessions: deleted_sessions,
      merchant_invitations: deleted_invitations,
      security_events: deleted_security_events
    }
  end
end