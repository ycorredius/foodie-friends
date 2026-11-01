class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :recipes, dependent: :destroy

  # Recipe quantities are shown to the user in this system.
  enum :unit_system, {us_customary: 0, metric: 1}, validate: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :first_name, :last_name, presence: true
  validates :password, length: {minimum: 8}, allow_nil: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
