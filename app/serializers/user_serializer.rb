# frozen_string_literal: true

class UserSerializer
  def self.call(user)
    {
      id: user.public_id,
      email: user.email,
      email_verified: user.email_verified?,
      has_password: user.has_password?,
      name: user.name,
      created_at: user.created_at.iso8601
    }
  end
end