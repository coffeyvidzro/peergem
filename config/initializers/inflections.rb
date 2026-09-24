# frozen_string_literal: true

ActiveSupport::Inflector.inflections(:en) do |inflect|
  # Payment
  inflect.acronym "GhIPSS"
  inflect.acronym "MoMo"
  inflect.acronym "GIP"
  inflect.acronym "MMI"
  inflect.acronym "ACH"

  # Tax orchestration
  inflect.acronym "AvaTax"

  # Compliance
  inflect.acronym "KYC"
  inflect.acronym "AML"

  # Authentication
  inflect.acronym "OTP"
end