# frozen_string_literal: true

module Geoip
  class Locate
      def self.call(ip_address)
        reader = Rails.application.config.x.geoip.reader
        return if reader.nil? || ip_address.blank?

        result = reader.city(ip_address.to_s)
        [result.city.name, result.country.name].compact_blank.join(", ").presence
      rescue StandardError => error
        Rails.logger.warn("GeoIP lookup failed: #{error.class}")
        nil
      end
    end
  end
end
