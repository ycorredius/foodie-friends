# A recipe planned for a household on a date and meal slot. A slot can hold
# several recipes (e.g. a main and a side), but each recipe only once. Weeks
# are just date ranges, so changing User#week_start_day never moves meals.
#
# Uses optimistic locking (lock_version): an update based on a stale version
# raises ActiveRecord::StaleObjectError. See docs/THINGS_TO_REVIEW.md for open
# questions about edits in shared households.
class PlannedMeal < ApplicationRecord
  belongs_to :household
  belongs_to :recipe

  enum :meal_slot, %i[breakfast lunch dinner snack], validate: true

  validates :date, presence: true
  validates :recipe_id, uniqueness: {scope: [:household_id, :date, :meal_slot], message: "is already planned for this meal"}
  validates :servings, numericality: {only_integer: true, in: 1..100}

  scope :between, ->(dates) { where(date: dates).order(:date, :meal_slot, :id) }
end
