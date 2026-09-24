# frozen_string_literal: true

# Keep abusive clients from creating unbounded transactions or email jobs. More
# specific account-level cooldowns are enforced by the challenge workflow.
Rack::Attack.throttle("auth/ip", limit: 30, period: 1.minute) do |request|
  request.ip if request.post? && request.path.start_with?("/auth/")
end
