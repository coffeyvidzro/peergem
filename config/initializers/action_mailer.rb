# frozen_string_literal: true

require "peergem/ses_v2_delivery"

ActionMailer::Base.add_delivery_method :ses_v2, Peergem::SesV2Delivery
