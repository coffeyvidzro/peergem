# frozen_string_literal: true

# The `money` gem is used for display and conversion only.

Money.locale_backend = :currency
Money.rounding_mode = BigDecimal::ROUND_HALF_UP
Money.default_currency = "GHS"
Money.default_infinite_precision = false