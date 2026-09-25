# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :context, :record

  def initialize(context, record)
    @context = context
    @record = record
  end

  private

  def membership
    context.membership
  end
end
