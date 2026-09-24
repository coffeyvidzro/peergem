# frozen_string_literal: true

class SecurityEvent < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :merchant, optional: true

  validates :event_type, :occurred_at, presence: true
  validate :metadata_is_object

  # Security events are an audit trail. Retention jobs may delete expired rows
  # in bulk, but application code cannot rewrite an event after it is stored.
  def readonly?
    persisted?
  end

  private

  def metadata_is_object
    errors.add(:metadata, "must be an object") unless metadata.is_a?(Hash)
  end
end
