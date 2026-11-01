# Deleting an account deactivates it: the user is signed out everywhere and
# their recipes are hidden. Signing in again within DELETION_GRACE_PERIOD
# reactivates it; after that, PurgeDeactivatedUsersJob deletes it permanently.
class User < ApplicationRecord
  DELETION_GRACE_PERIOD = 30.days

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :recipes, dependent: :destroy

  # Recipe quantities are shown to the user in this system.
  enum :unit_system, {us_customary: 0, metric: 1}, validate: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :first_name, :last_name, presence: true
  validates :password, length: {minimum: 8}, allow_nil: true

  scope :active, -> { where(deactivated_at: nil) }
  scope :due_for_deletion, -> { where(deactivated_at: ..DELETION_GRACE_PERIOD.ago) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def deactivated?
    deactivated_at.present?
  end

  def deactivate!
    transaction do
      update!(deactivated_at: Time.current)
      sessions.destroy_all
    end
  end

  # Returns true if the account was deactivated and is now active again.
  def reactivate
    return false unless deactivated?

    update!(deactivated_at: nil)
    true
  end

  def deletes_at
    deactivated_at + DELETION_GRACE_PERIOD if deactivated?
  end
end
