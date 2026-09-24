# lib/tasks/geoip.rake
# frozen_string_literal: true

require "fileutils"
require "open-uri"
require "rubygems/package"
require "zlib"

namespace :geoip do
  desc "Download and atomically replace the GeoLite2-City database"
  task refresh: :environment do
    license_key = Rails.application.credentials.dig(:maxmind, :license_key) ||
                  ENV["MAXMIND_LICENSE_KEY"]

    if license_key.blank?
      abort "MAXMIND_LICENSE_KEY is not set. " \
            "Add it to Rails credentials under maxmind.license_key, " \
            "or export it as an environment variable."
    end

    target_path = Rails.root.join("vendor", "geoip", "GeoLite2-City.mmdb")
    FileUtils.mkdir_p(target_path.dirname)

    url = "https://download.maxmind.com/app/geoip_download" \
          "?edition_id=GeoLite2-City&license_key=#{license_key}&suffix=tar.gz"

    Dir.mktmpdir("geoip") do |tmpdir|
      archive_path = File.join(tmpdir, "GeoLite2-City.tar.gz")
      extract_dir  = File.join(tmpdir, "extracted")
      FileUtils.mkdir_p(extract_dir)

      puts "Downloading GeoLite2-City..."
      URI.open(url, "rb") do |remote|
        File.open(archive_path, "wb") { |local| IO.copy_stream(remote, local) }
      end

      puts "Extracting..."
      Zlib::GzipReader.open(archive_path) do |gzip|
        Gem::Package::TarReader.new(gzip) do |tar|
          tar.each do |entry|
            next unless entry.file?
            next unless entry.full_name.end_with?("GeoLite2-City.mmdb")

            dest = File.join(extract_dir, "GeoLite2-City.mmdb")
            File.open(dest, "wb") { |f| IO.copy_stream(entry, f) }
          end
        end
      end

      extracted_mmdb = File.join(extract_dir, "GeoLite2-City.mmdb")
      unless File.file?(extracted_mmdb)
        abort "Extraction failed: GeoLite2-City.mmdb not found in archive."
      end

      FileUtils.mv(extracted_mmdb, target_path)
      puts "Replaced #{target_path}"
    end

    # Reload the reader so the running process picks up the new database.
    # In a multi-process deployment, each Puma worker and Sidekiq process
    # must be restarted or must reload this task manually.
    if defined?(Rails.application.config.x.geoip)
      Rails.application.config.x.geoip.reader =
        MaxMind::GeoIP2::Reader.new(database: target_path.to_s)
      puts "Reader reloaded."
    end
  end
end
