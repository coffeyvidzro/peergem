# frozen_string_literal: true

require "pagy"

# Pagy 43 ships pagination types in core and configures them through OPTIONS.
# Freeze the global options after application defaults are assigned.
Pagy::OPTIONS[:limit] = 20
Pagy::OPTIONS[:client_limit] = 100
Pagy::OPTIONS.freeze
