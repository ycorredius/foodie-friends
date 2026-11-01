class HouseholdMembership < ApplicationRecord
  belongs_to :household
  belongs_to :user

  validates :user_id, uniqueness: true

  # A household with no members left is deleted, along with its plans.
  after_destroy_commit { household.destroy if household.memberships.none? }
end
