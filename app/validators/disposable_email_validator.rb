# frozen_string_literal: true

require "set"

class DisposableEmailValidator < ActiveModel::EachValidator
  BLOCKLIST_PATH = Rails.root.join("lib/data/disposable_emails.txt")
  BLOCKED_DOMAINS = File.foreach(BLOCKLIST_PATH, chomp: true).each_with_object(Set.new) do |line, domains|
    domain = line.strip.downcase.delete_suffix(".")
    domains << domain unless domain.blank? || domain.start_with?("#")
  end.freeze

  def validate_each(record, attribute, value)
    domain = value.to_s.rpartition("@").last.strip.downcase.delete_suffix(".")
    return if domain.blank?
    return unless blocked_domain?(domain)

    record.errors.add(attribute, options.fetch(:message, "must not use a disposable email provider"))
  end

  private

  def blocked_domain?(domain)
    labels = domain.split(".")
    labels.each_index.any? { |index| BLOCKED_DOMAINS.include?(labels.drop(index).join(".")) }
  end
end
