# == Schema Information
#
# Table name: api_tokens
#
#  id           :bigint           not null, primary key
#  expires_at   :datetime         not null
#  last_used_at :datetime
#  token_digest :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_api_tokens_on_token_digest  (token_digest) UNIQUE
#  index_api_tokens_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

# A bearer token for the JSON API. Only a SHA-256 digest is stored; the
# plaintext token is available via #token on the instance that created it and
# must be handed to the client then. Tokens expire after TTL of inactivity.
class ApiToken < ApplicationRecord
  TTL = 30.days

  belongs_to :user

  attr_reader :token

  before_validation :generate_token, on: :create

  validates :token_digest, presence: true, uniqueness: true

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token)
  end

  # Returns the active token matching the plaintext token and slides its
  # expiry forward, or nil.
  def self.authenticate(token)
    return if token.blank?

    api_token = active.find_by(token_digest: digest(token))
    api_token&.refresh!
    api_token
  end

  def expired?
    expires_at <= Time.current
  end

  def refresh!
    update_columns(last_used_at: Time.current, expires_at: TTL.from_now)
  end

  private

  def generate_token
    @token = SecureRandom.base58(32)
    self.token_digest = self.class.digest(@token)
    self.expires_at = TTL.from_now
  end
end
