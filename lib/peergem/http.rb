# frozen_string_literal: true

module Peergem
  module Http
    module_function

    # Shared defaults for outbound integrations. Callers provide a base URL and
    # may add authentication in the block without giving up retry behavior.
    def connection(url:, &)
      Faraday.new(url:) do |faraday|
        faraday.request :retry,
          max: 2,
          interval: 0.1,
          backoff_factor: 2,
          retry_statuses: [ 429, 502, 503, 504 ]
        faraday.request :json
        faraday.response :json, content_type: /json/
        faraday.response :raise_error
        yield faraday if block_given?
      end
    end
  end
end
