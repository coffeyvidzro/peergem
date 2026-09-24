# frozen_string_literal: true

require "maxmind/geoip2"

database_path = Pathname.new(
  ENV.fetch(
    "GEOIP_DATABASE_PATH",
    Rails.root.join("vendor", "geoip", "GeoLite2-City.mmdb")
  )
)

Rails.application.config.x.geoip.database_path = database_path
Rails.application.config.x.geoip.reader =
  if database_path.file?
    MaxMind::GeoIP2::Reader.new(database: database_path.to_s)
  end