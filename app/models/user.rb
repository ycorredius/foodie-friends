# Deleting an account deactivates it: the user is signed out everywhere and
# their recipes are hidden. Signing in again within DELETION_GRACE_PERIOD
# reactivates it; after that, PurgeDeactivatedUsersJob deletes it permanently.
class User < ApplicationRecord
  DELETION_GRACE_PERIOD = 30.days

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :recipes, dependent: :destroy
  has_many :saved_recipes, dependent: :destroy
  # One household per user for now; see docs/ROADMAP.md for multi-household managers.
  has_one :household_membership, dependent: :destroy
  has_one :household, through: :household_membership

  # Every user gets a household of one at sign-up.
  after_create :create_default_household

  has_many :follows_given, class_name: "Follow", foreign_key: :follower_id, dependent: :destroy, inverse_of: :follower
  has_many :follows_received, class_name: "Follow", foreign_key: :followed_id, dependent: :destroy, inverse_of: :followed
  has_many :following, -> { merge(Follow.accepted) }, through: :follows_given, source: :followed
  has_many :followers, -> { merge(Follow.accepted) }, through: :follows_received, source: :follower

  # Making a profile public approves its pending follow requests.
  after_update :approve_pending_follow_requests, if: -> { saved_change_to_private_profile?(to: false) }

  # Recipe quantities are shown to the user in this system.
  enum :unit_system, {us_customary: 0, metric: 1}, validate: true
  # The first day of the week in the meal planner.
  enum :week_start_day, {sunday: 0, monday: 1}, prefix: :week_starts, validate: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :first_name, :last_name, presence: true
  validates :password, length: {minimum: 8}, allow_nil: true

  scope :active, -> { where(deactivated_at: nil) }
  scope :due_for_deletion, -> { where(deactivated_at: ..DELETION_GRACE_PERIOD.ago) }

  # Active users whose profile content (recipes, follower lists) the viewer may
  # see: public profiles, plus private profiles the viewer follows.
  def self.content_visible_to(viewer)
    active.where(private_profile: false).or(active.where(id: viewer.follows_given.accepted.select(:followed_id)))
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  # The dates of the planner week containing `date`, per week_start_day.
  def week_containing(date)
    start = date.beginning_of_week(week_start_day.to_sym)
    start..(start + 6.days)
  end

  def deactivated?
    deactivated_at.present?
  end

  # Follows the user, or requests to if their profile is private. Returns the
  # Follow; following someone twice returns the existing one.
  def follow(user)
    follows_given.find_or_create_by!(followed: user) do |follow|
      follow.status = user.private_profile? ? :pending : :accepted
    end
  end

  # Unfollows the user, or cancels a pending request.
  def unfollow(user)
    follows_given.where(followed: user).destroy_all
  end

  def following?(user)
    follows_given.accepted.exists?(followed: user)
  end

  # Whether the viewer may see this user's profile content.
  def content_visible_to?(viewer)
    !private_profile? || viewer == self || viewer.following?(self)
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

  private

  def create_default_household
    create_household_membership!(household: Household.create!(name: "#{first_name}'s household"))
  end

  def approve_pending_follow_requests
    follows_received.pending.update_all(status: Follow.statuses[:accepted], updated_at: Time.current)
  end
end
