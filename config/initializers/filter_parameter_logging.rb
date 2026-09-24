# frozen_string_literal: true

# Act 843 compliance boundary.
#
# No PII (email, phone, MoMo MSISDN, Ghana Card, card PAN, or any combination
# that can identify a data subject) may leave PeerGem's infrastructure to any
# third-party service — Sentry, log aggregators, APM tools, error trackers.


Rails.application.config.filter_parameters += [
  # Rails defaults — keep these, they are battle-tested
  :passw,
  :secret,
  :token,
  :_key,
  :crypt,
  :salt,
  :certificate,
  :otp,
  :ssn,
  :cvv,
  :cvc,

  # PeerGem additions — fintech-specific PII
  :email,
  :phone,
  :momo_number,
  :msisdn,
  :ghana_card,
  :ghana_card_number,
  :card_number,
  :card_pan,
  :pin,
  :otp_code,
  :authorization,
  :cookie,
  :bvn,
  :bank_account
]
