# frozen_string_literal: true

class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json(*)
    {
      id: @user.public_id,
      email: @user.email,
      email_verified: @user.confirmed?,
      has_password: @user.password_digest.present?,
      name: @user.name,
      created_at: @user.created_at.iso8601
    }
  end
end
