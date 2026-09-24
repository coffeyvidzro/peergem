# frozen_string_literal: true

require "maxmind/geoip2"

# PeerGem Radar: local GeoIP2 lookups for risk scoring.

database_path = ENV.fetch(
  "GEOIP_DATABASE_PATH",
  Rails.root.join("vendor", "geoip", "GeoLite2-City.mmdb").to_s
)

Rails.application.config.x.geoip ||= ActiveSupport::OrderedOptions.new
Rails.application.config.x.geoip.database_path = database_path

Rails.application.config.x.geoip.reader =
  if File.file?(database_path)
    MaxMind::GeoIP2::Reader.new(database: database_path)
  end