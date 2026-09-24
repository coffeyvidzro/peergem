# frozen_string_literal: true

require "aws-sdk-sesv2"

module Peergem
  # Action Mailer delivery adapter backed by the SES v2 raw-email API.
  # Sending the complete RFC 822 message preserves Rails attachments and headers.
  class SesV2Delivery
    def initialize(settings = {})
      @client = Aws::SESV2::Client.new(
        region: settings[:region] || ENV.fetch("AWS_REGION", "us-east-1")
      )
    end

    def deliver!(mail)
      @client.send_email(
        from_email_address: mail.from&.first,
        destination: {
          to_addresses: mail.to,
          cc_addresses: mail.cc,
          bcc_addresses: mail.bcc
        }.compact,
        content: { raw: { data: mail.to_s } }
      )
    end
  end
end
