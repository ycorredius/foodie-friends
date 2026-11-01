# The people a user plans and shops for. Every user gets one at sign-up;
# meal plans belong to the household so members can share them later.
class Household < ApplicationRecord
  has_many :memberships, class_name: "HouseholdMembership", dependent: :destroy
  has_many :members, through: :memberships, source: :user
  has_many :planned_meals, dependent: :destroy

  validates :name, presence: true, length: {maximum: 60}
  # Number of people being fed; the default servings for planned meals.
  validates :size, numericality: {only_integer: true, in: 1..20}
end
