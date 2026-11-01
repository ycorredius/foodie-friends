# A signed-in device. Browsers find their session by id from a signed cookie;
# API clients send the session's token as "Authorization: Bearer <token>".
#
# Only a SHA-256 digest of the token is stored. The plaintext is available via
# #token on the instance that created it, and must be handed to the client then.
# Sessions expire after TTL without use.
class Session < ApplicationRecord
  TTL = 30.days
  # Extend expiry at most this often, so active sessions don't write on every request.
  REFRESH_INTERVAL = 1.hour

  belongs_to :user

  attr_reader :token

  before_validation :generate_token, on: :create

  scope :active, -> { where(expires_at: Time.current..) }

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token)
  end

  def self.find_by_token(token)
    active.find_by(token_digest: digest(token)) if token.present?
  end

  def extend_expiry
    update_columns(expires_at: TTL.from_now, updated_at: Time.current) if expires_at < TTL.from_now - REFRESH_INTERVAL
    self
  end

  private

  def generate_token
    @token = SecureRandom.base58(32)
    self.token_digest = self.class.digest(@token)
    self.expires_at = TTL.from_now
  end
end
