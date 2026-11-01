class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :first_name, :last_name, presence: true
  validates :password, length: {minimum: 8}, allow_nil: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
