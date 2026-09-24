# frozen_string_literal: true

class SecurityEvent < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :merchant, optional: true

  validates :event_type, :occurred_at, presence: true
  validate :metadata_is_object

  private

  def metadata_is_object
    errors.add(:metadata, "must be an object") unless metadata.is_a?(Hash)
  end
end