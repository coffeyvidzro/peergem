# frozen_string_literal: true

class SessionPolicy
  def initialize(user, session)
    @user = user
    @session = session
  end

  def show?
    @session.user_id == @user.id
  end
end
