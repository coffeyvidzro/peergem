# frozen_string_literal: true

module Integrations
  module Geoip
    class Locate
      def self.call(ip_address:)
        reader = Rails.application.config.x.geoip.reader
        return unless reader && ip_address

        result = reader.city(ip_address.to_s)
        [ result.city.name, result.country.name ].compact_blank.join(", ").presence
      rescue StandardError
        nil
      end
    end
  end
end
