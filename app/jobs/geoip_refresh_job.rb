# app/jobs/geoip_refresh_job.rb
class GeoipRefreshJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 2

  def perform
    Rake::Task["geoip:refresh"].reenable
    Rake::Task["geoip:refresh"].invoke
  end
end