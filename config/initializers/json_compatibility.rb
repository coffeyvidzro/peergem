# frozen_string_literal: true

# Rails 8.1.3.1 passes JSON parsing options positionally, while json 3 requires
# keywords. Remove this compatibility shim after upgrading Rails to a release
# containing the upstream JSON decoding fix.
module ActiveSupport
  module JSON
    class << self
      def decode(json, options = {})
        data = ::JSON.parse(json, **options)
        ActiveSupport.parse_json_times ? convert_dates_from(data) : data
      end

      alias_method :load, :decode
    end
  end
end
