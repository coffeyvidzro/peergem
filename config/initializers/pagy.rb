# frozen_string_literal: true

# Pagy 43 global defaults.
# See: https://ddnexus.github.io/pagy/toolbox/configuration/options/
#
# These are inherited by all paginators and helpers. Freeze after setting
# so that runtime code cannot accidentally mutate global pagination state.

Pagy::OPTIONS[:limit] = 20
Pagy::OPTIONS[:max_limit] = 100
Pagy::OPTIONS.freeze